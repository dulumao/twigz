namespace TwigZ;


/**
 * Stores the Twig configuration.
 *
 */
class Environment
{
	const VERSION = "1.16.2";

	protected charset;
	protected loader;
	protected debug;
	protected autoReload;
	protected cache;
	protected lexer;
	protected parser;
	protected compiler;
	protected baseTemplateClass;
	protected extensions;
	protected parsers;
	protected visitors;
	protected filters;
	protected tests;
	protected functions;
	protected globals;
	protected runtimeInitialized;
	protected extensionInitialized;
	protected loadedTemplates;
	protected strictVariables;
	protected unaryOperators;
	protected binaryOperators;
	protected templateClassPrefix = "__TwigTemplate_";
	protected functionCallbacks;
	protected filterCallbacks;
	protected staging;

	/**
	 * Constructor.
	 *
	 * Available options:
	 *
	 *  * debug: When set to true, it automatically set "auto_reload" to true as
	 *           well (default to false).
	 *
	 *  * charset: The charset used by the templates (default to UTF-8).
	 *
	 *  * base_template_class: The base template class to use for generated
	 *                         templates (default to \TwigZ\Template).
	 *
	 *  * cache: An absolute path where to store the compiled templates, or
	 *           false to disable compilation cache (default).
	 *
	 *  * auto_reload: Whether to reload the template if the original source changed.
	 *                 If you don"t provide the auto_reload option, it will be
	 *                 determined automatically based on the debug value.
	 *
	 *  * strict_variables: Whether to ignore invalid variables in templates
	 *                      (default to false).
	 *
	 *  * autoescape: Whether to enable auto-escaping (default to html):
	 *                  * false: disable auto-escaping
	 *                  * true: equivalent to html
	 *                  * html, js: set the autoescaping to one of the supported strategies
	 *                  * filename: set the autoescaping strategy based on the template filename extension
	 *                  * PHP callback: a PHP callback that returns an escaping strategy based on the template "filename"
	 *
	 *  * optimizations: A flag that indicates which optimizations to apply
	 *                   (default to -1 which means that all optimizations are enabled;
	 *                   set it to 0 to disable).
	 *
	 * @param \TwigZ\LoaderInterface $loader  A \TwigZ\LoaderInterface instance
	 * @param array                $options An array of options
	 */

	public function __construct(<\TwigZ\LoaderInterface> loader = null, options = [])
	{

		if (null !== loader) {
			this->setLoader(loader);
		}

		let options = array_merge([
			"debug"               : false,
			"charset"             : "UTF-8",
			"base_template_class" : "\\TwigZZ\\Template",
			"strict_variables"    : false,
			"autoescape"          : "html",
			"cache"               : false,
			"auto_reload"         : null,
			"optimizations"       : -1
		], options);

		let this->debug              = (bool) options["debug"];
		let this->charset            = strtoupper(options["charset"]);
		let this->baseTemplateClass  = options["base_template_class"];
		let this->autoReload         = null === options["auto_reload"] ? this->debug : (bool) options["auto_reload"];
		let this->strictVariables    = (bool) options["strict_variables"];
		let this->runtimeInitialized = false;
		let this->functionCallbacks = [];
		let this->filterCallbacks = [];

		this->setCache(options["cache"]);
		this->addExtension(new \TwigZ\Extension\Core());
		this->addExtension(new \TwigZ\Extension\Escaper(options["autoescape"]));
		this->addExtension(new \TwigZ\Extension_Optimizer(options["optimizations"]));

		let this->extensionInitialized = false;
		let this->staging = new \TwigZ\Extension\Staging();
	}

	/**
	 * Gets the base template class for compiled templates.
	 *
	 * @return string The base template class name
	 */
	public function getBaseTemplateClass()
	{
		return this->baseTemplateClass;
	}

	/**
	 * Sets the base template class for compiled templates.
	 *
	 * @param string $class The base template class name
	 */
	public function setBaseTemplateClass(className)
	{
		let this->baseTemplateClass = className;
	}

	/**
	 * Enables debugging mode.
	 */
	public function enableDebug()
	{
		let this->debug = true;
	}

	/**
	 * Disables debugging mode.
	 */
	public function disableDebug()
	{
		let this->debug = true;
	}

	/**
	 * Checks if debug mode is enabled.
	 *
	 * @return bool true if debug mode is enabled, false otherwise
	 */
	public function isDebug()
	{
		return this->debug;
	}

	/**
	 * Enables the auto_reload option.
	 */
	public function enableAutoReload()
	{
		let this->autoReload = true;
	}
	
	/**
	 * Disables the auto_reload option.
	 */
	public function disableAutoReload()
	{
		let this->autoReload = false;
	}

	/**
	 * Checks if the auto_reload option is enabled.
	 *
	 * @return bool true if auto_reload is enabled, false otherwise
	 */
	public function isAutoReload()
	{
		return this->autoReload;
	}

	/**
	 * Enables the strict_variables option.
	 */
	public function enableStrictVariables()
	{
		let this->strictVariables = true;
	}

	/**
	 * Disables the strict_variables option.
	 */
	public function disableStrictVariables()
	{
		let this->strictVariables = false;
	}

	/**
	 * Checks if the strict_variables option is enabled.
	 *
	 * @return bool true if strict_variables is enabled, false otherwise
	 */
	public function isStrictVariables()
	{
		return this->strictVariables;
	}

	/**
	 * Gets the cache directory or false if cache is disabled.
	 *
	 * @return string|false
	 */
	public function getCache()
	{
		return this->cache;
	}

	/**
	 * Sets the cache directory or false if cache is disabled.
	 *
	 * @param string|false $cache The absolute path to the compiled templates,
	 *                            or false to disable cache
	 */
	public function setCache(cache)
	{
		let this->cache = cache ? cache : false;
	}

	/**
	 * Gets the cache filename for a given template.
	 *
	 * @param string $name The template name
	 *
	 * @return string|false The cache file name or false when caching is disabled
	 */
	public function getCacheFilename(name)
	{
		string className;

		if (false === this->cache) {
			return false;
		}

		let className = substr(this->getTemplateClass(name), strlen(this->templateClassPrefix));

		return this->getCache()."/".substr(className, 0, 2)."/".substr(className, 2, 2)."/".substr(className, 4).".php";
	}

	/**
	 * Gets the template class associated with the given string.
	 *
	 * @param string $name  The name for which to calculate the template class name
	 * @param int    $index The index if it is an embedded template
	 *
	 * @return string The template class name
	 */
	public function getTemplateClass(name, index = null)
	{
		return this->templateClassPrefix.hash("sha256", this->getLoader()->getCacheKey(name)).(null === index ? "" : "_".index);
	}

	/**
	 * Gets the template class prefix.
	 *
	 * @return string The template class prefix
	 */
	public function getTemplateClassPrefix()
	{
		return this->templateClassPrefix;
	}

	/**
	 * Renders a template.
	 *
	 * @param string $name    The template name
	 * @param array  $context An array of parameters to pass to the template
	 *
	 * @return string The rendered template
	 *
	 * @throws \TwigZ\Error_Loader  When the template cannot be found
	 * @throws \TwigZ\Error_Syntax  When an error occurred during compilation
	 * @throws \TwigZ\Error_Runtime When an error occurred during rendering
	 */
	public function render(name, array! context = [])
	{
		return this->loadTemplate(name)->render(context);
	}

	/**
	 * Displays a template.
	 *
	 * @param string $name    The template name
	 * @param array  $context An array of parameters to pass to the template
	 *
	 * @throws \TwigZ\Error_Loader  When the template cannot be found
	 * @throws \TwigZ\Error_Syntax  When an error occurred during compilation
	 * @throws \TwigZ\Error_Runtime When an error occurred during rendering
	 */
	public function display(name, array! context = [])
	{
		this->loadTemplate(name)->display(context);
	}

	/**
	 * Loads a template by name.
	 *
	 * @param string $name  The template name
	 * @param int    $index The index if it is an embedded template
	 *
	 * @return \TwigZ\TemplateInterface A template instance representing the given template name
	 *
	 * @throws \TwigZ\Error\Loader When the template cannot be found
	 * @throws \TwigZ\Error\Syntax When an error occurred during compilation
	 */
	public function loadTemplate(name, index = null)
	{
		var cls, cache;
		let cls = this->getTemplateClass(name, index);

		if (isset(this->loadedTemplates[cls])) {
			return this->loadedTemplates[cls];
		}

		if (!class_exists(cls, false)) {
			let cache = this->getCacheFilename(name);
			if (false === cache) {
				//eval("?>".this->compileSource(this->getLoader()->getSource(name), name));
			} else {
				if (!is_file(cache) || (this->isAutoReload() && !this->isTemplateFresh(name, filemtime(cache)))) {
					this->writeCacheFile(cache, this->compileSource(this->getLoader()->getSource(name), name));
				}
				//: Check this part
				//require_once cache;
			}
		}

		if (!this->runtimeInitialized) {
			this->initRuntime();
		}

		let this->loadedTemplates[cls] = new cls(this);

		return this->loadedTemplates[cls];
	}

	/**
	 * Returns true if the template is still fresh.
	 *
	 * Besides checking the loader for freshness information,
	 * this method also checks if the enabled extensions have
	 * not changed.
	 *
	 * @param string    $name The template name
	 * @param timestamp $time The last modification time of the cached template
	 *
	 * @return bool    true if the template is fresh, false otherwise
	 */
	public function isTemplateFresh(name, time)
	{
		var r, extension;
		for k, extension in this->exrtensions {
			let r = new ReflectionObject(extension);
			if (filemtime(r->getFileName()) > time) {
				return false;
			}
		}

		return this->getLoader()->isFresh(name, time);
	}

	/**
	 * Tries to load a template consecutively from an array.
	 *
	 * Similar to loadTemplate() but it also accepts Twig_TemplateInterface instances and an array
	 * of templates where each is tried to be loaded.
	 *
	 * @param string|\TwigZ\Template|array $names A template or an array of templates to try consecutively
	 *
	 * @return \TwigZ\Template
	 *
	 * @throws \TwigZ\Error\Loader When none of the templates can be found
	 * @throws \TwigZ\Error\Syntax When an error occurred during compilation
	 */
	 public function resolveTemplate(names)
	 {
		array names;
		var e;

		if (!is_array(names)) {
			let names = [names];
		}

		for k, name in names {
			if (name instanceof \TwigZ\Template) {
				return name;
			}

			try {
				return this->loadTemplate(name);
			} catch \TwigZ\Error\Loader, e {
			}
		}

		if (1 === count(names)) {
			throw e;
		}

		throw new \TwigZ\Error\Loader(sprintf("Unable to find one of the following templates: \"%s\".", implode("\", \"", names)));

	 }

	/**
	 * Clears the internal template cache.
	 */
	public function clearTemplateCache()
	{
		let this->loadedTemplates = [];
	}

	/**
	 * Clears the template cache files on the filesystem.
	 */
	public function clearCacheFiles()
	{
		var files;
		if (false === this->cache) {
			return;
		}

		let files = new RecursiveIteratorIterator(new RecursiveDirectoryIterators(this->cahe), RecursiveIteratorIterator::LEAVES_ONLY);
		for k, file in files {
			if (file->isFile()) {
				@unlink(file->getPathname());
			}
		}
	}

	/**
	 * Gets the Lexer instance.
	 *
	 * @return \TwigZ\LexerInterface A Twig_LexerInterface instance
	 */
	public function getLexer()
	{
		if (null === this->lexer) {
			let this->lexer = new \TwigZ\Lexer(this);
		}

		return this->lexer;
	}

	/**
	 * Sets the Lexer instance.
	 *
	 * @param \TwigZ\LexerInterface A \TwigZ\LexerInterface instance
	 */
	public function setLexer(<\TwigZ\LexerInterface> lexer)
	{
		let this->lexer = lexer;
	}

	/**
	 * Tokenizes a source code.
	 *
	 * @param string $source The template source code
	 * @param string $name   The template name
	 *
	 * @return \TwigZ\TokenStream A Twig_TokenStream instance
	 *
	 * @throws \TwigZ\Error\Syntax When the code is syntactically wrong
	 */
	public function tokenize(source, name = null)
	{
		return this->getLexer()->tokenize(source, name);
	}

	/**
	 * Gets the Parser instance.
	 *
	 * @return \TwigZ\ParserInterface A \TwigZ\ParserInterface instance
	 */
	public function getParser()
	{
		if (null === this->parser) {
			let this->parser = new Twig_Parser(this);
		}

		return this->parser;
	}

	/**
	 * Sets the Parser instance.
	 *
	 * @param \TwigZ\ParserInterface A \TwigZ\ParserInterface instance
	 */
	public function setParser(<\TwigZ\ParserInterface> parser)
	{
		let this->parser = parser;
	}

	/**
	 * Converts a token stream to a node tree.
	 *
	 * @param \TwigZ\TokenStream $stream A token stream instance
	 *
	 * @return \TwigZ\Node\Module A node tree
	 *
	 * @throws \TwigZ\Error\Syntax When the token stream is syntactically or semantically wrong
	 */
	public function parse(<\TwigZ\TokenStream stream)
	{
		return this->getParser()->parse(stream);
	}

	/**
	 * Gets the Compiler instance.
	 *
	 * @return \TwigZ\CompilerInterface A \TwigZ\CompilerInterface instance
	 */
	public function getCompiler()
	{
		if (null === this->compiler) {
			let this->compiler = new \TwigZ\Compiler(this);
		}

		return this->compiler;
	}

	/**
	 * Sets the Compiler instance.
	 *
	 * @param \TwigZ\CompilerInterface $compiler A \TwigZ\CompilerInterface instance
	 */
	public function setCompiler(<\TwigZ\CompilerInterface> compiler)
	{
		let this->compiler = compiler;
	}

	/**
	 * Compiles a node and returns the PHP code.
	 *
	 * @param \TwigZ\NodeInterface $node A Twig_NodeInterface instance
	 *
	 * @return string The compiled PHP source code
	 */
	public function compile(<\TwigZ\NodeInterface> node)
	{
		return this->getCompiler()->compile(node)->getSource();
	}

	/**
	 * Compiles a template source code.
	 *
	 * @param string $source The template source code
	 * @param string $name   The template name
	 *
	 * @return string The compiled PHP source code
	 *
	 * @throws \TwigZ\Error\Syntax When there was an error during tokenizing, parsing or compiling
	 */
	public function compileSource(source, name = null)
	{
		var e;

		try {
			return this->compile(this->parse(this->tokenize(source, name)));
		} catch \TwigZ\Error, e {
			e->setTemplateFile(name);
			throw e;
		} catch \Exception, e {
			throw new \TwigZ\Error\Syntax(sprintf("An exception has been thrown during the compilation of a template (\"%s\").", e->getMessage()), -1, name, e);
		}
	}

    /**
     * Sets the Loader instance.
     *
     * @param \TwigZ\LoaderInterface $loader A \TwigZ\LoaderInterface instance
     */
    public function setLoader(<\TwigZ\LoaderInterface loader)
    {
        let this->loader = loader;
    }

    /**
     * Gets the Loader instance.
     *
     * @return \TwigZ\LoaderInterface A \TwigZ\LoaderInterface instance
     */
    public function getLoader()
    {
        if (null === this->loader) {
            throw new \LogicException("You must set a loader first.");
        }

        return this->loader;
    }

    /**
     * Sets the default template charset.
     *
     * @param string $charset The default charset
     */
    public function setCharset(charset)
    {
        let this->charset = strtoupper(charset);
    }

    /**
     * Gets the default template charset.
     *
     * @return string The default charset
     */
    public function getCharset()
    {
        return this->charset;
    }

    /**
     * Initializes the runtime environment.
     */
    public function initRuntime()
    {
        let this->runtimeInitialized = true;

        for k, extension in this->getExtensions() {
            extension->initRuntime(this);
        }
    }

    /**
     * Returns true if the given extension is registered.
     *
     * @param string $name The extension name
     *
     * @return bool    Whether the extension is registered or not
     */
    public function hasExtension(name)
    {
        return isset(this->extensions[name]);
    }

    /**
     * Gets an extension by name.
     *
     * @param string $name The extension name
     *
     * @return \TwigZ\ExtensionInterface A \TwigZ\ExtensionInterface instance
     */
    public function getExtension(name)
    {
        if (!isset(this->extensions[name])) {
            throw new \TwigZ\Error\Runtime(sprintf("The \"%s\" extension is not enabled.", name));
        }

        return this->extensions[name];
    }

    /**
     * Registers an extension.
     *
     * @param \TwigZ\ExtensionInterface $extension A \TwigZ\ExtensionInterface instance
     */
    public function addExtension(<\TwigZ\ExtensionInterface extension)
    {
        if (this->extensionInitialized) {
            throw new \LogicException(sprintf("Unable to register extension \"%s\" as extensions have already been initialized.", extension->getName()));
        }

        let this->extensions[extension->getName()] = extension;
    }

    /**
     * Removes an extension by name.
     *
     * This method is deprecated and you should not use it.
     *
     * @param string $name The extension name
     *
     * @deprecated since 1.12 (to be removed in 2.0)
     */
    public function removeExtension(name)
    {
        if (this->extensionInitialized) {
            throw new \LogicException(sprintf("Unable to remove extension \"%s\" as extensions have already been initialized.", name));
        }

        unset(this->extensions[name]);
    }
}