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
				//TODO: Check this part
				require cache;
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
		for extension in this->extensions {
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
		var name, e;

		if (!is_array(names)) {
			let names = [names];
		}

		for name in names {
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
		var file, files, atunlink;
		let atunlink = "@unlink";

		if (false === this->cache) {
			return;
		}

		let files = new \RecursiveIteratorIterator(new \RecursiveDirectoryIterator(this->cache), \RecursiveIteratorIterator::LEAVES_ONLY);
		for file in files {
			if (file->isFile()) {
				{atunlink}(file->getPathname());
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
	public function parse(<\TwigZ\TokenStream> stream)
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
    public function setLoader(<\TwigZ\LoaderInterface> loader)
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
    	var extension;

        let this->runtimeInitialized = true;

        for extension in this->getExtensions() {
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
    public function addExtension(<\TwigZ\ExtensionInterface> extension)
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

    /**
     * Registers an array of extensions.
     *
     * @param array $extensions An array of extensions
     */
    public function setExtensions(array! extensions)
    {
    	var extension;

    	for extension in extensions {
    		this->addExtension(extension);
    	}
    }

    /**
     * Returns all registered extensions.
     *
     * @return array An array of extensions
     */
    public function getExtensions()
    {
        return this->extensions;
    }

    /**
     * Registers a Token Parser.
     *
     * @param \TwigZ\TokenParserInterface $parser A \TwigZ\TokenParserInterface instance
     */
    public function addTokenParser(<TwigZ\TokenParserInterface> parser)
    {
        if (this->extensionInitialized) {
            throw new \LogicException("Unable to add a token parser as extensions have already been initialized.");
        }

        this->staging->addTokenParser(parser);
    }

    /**
     * Gets the registered Token Parsers.
     *
     * @return \TwigZ\TokenParserBrokerInterface A broker containing token parsers
     */
    public function getTokenParsers()
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        return this->parsers;
    }

    /**
     * Gets registered tags.
     *
     * Be warned that this method cannot return tags defined by \TwigZ\TokenParserBrokerInterface classes.
     *
     * @return \TwigZ\TokenParserInterface[] An array of \TwigZ\TokenParserInterface instances
     */
    public function getTags()
    {
    	array tags;
    	var parser;

        let tags = [];
        for parser in this->getTokenParsers()->getParsers() {
            if (parser instanceof \TwigZ\TokenParserInterface) {
                let tags[parser->getTag()] = parser;
            }
        }

        return tags;
    }

    /**
     * Registers a Node Visitor.
     *
     * @param \TwigZ\NodeVisitorInterface $visitor A \TwigZ\NodeVisitorInterface instance
     */
    public function addNodeVisitor(<TwigZ\NodeVisitorInterface> visitor)
    {
        if (this->extensionInitialized) {
            throw new LogicException("Unable to add a node visitor as extensions have already been initialized.");
        }

        this->staging->addNodeVisitor(visitor);
    }

    /**
     * Gets the registered Node Visitors.
     *
     * @return \TwigZ\NodeVisitorInterface[] An array of \TwigZ\NodeVisitorInterface instances
     */
    public function getNodeVisitors()
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        return this->visitors;
    }

    /**
     * Registers a Filter.
     *
     * @param string|\TwigZ\SimpleFilter               $name   The filter name or a \TwigZ\SimpleFilter instance
     * @param \TwigZ\FilterInterface|\TwigZ\SimpleFilter $filter A \TwigZ\FilterInterface instance or a \TwigZ\SimpleFilter instance
     */
    public function addFilter(name, filter = null)
    {
        if (!(name instanceof \TwigZ\SimpleFilter) && (!(filter instanceof \TwigZ\SimpleFilter) || filter instanceof \TwigZ\FilterInterface)) {
            throw new \LogicException("A filter must be an instance of \\TwigZ\\FilterInterface or \\TwigZ\\SimpleFilter");
        }

        if (name instanceof \TwigZ\SimpleFilter) {
            let filter = name;
            let name = filter->getName();
        }

        if (this->extensionInitialized) {
            throw new \LogicException(sprintf("Unable to add filter \"%s\" as extensions have already been initialized.", $name));
        }

        this->staging->addFilter(name, filter);
    }

    /**
     * Get a filter by name.
     *
     * Subclasses may override this method and load filters differently;
     * so no list of filters is available.
     *
     * @param string $name The filter name
     *
     * @return \TwigZ\Filter|false A \TwigZ\Filter instance or false if the filter does not exist
     */
    public function getFilter(name)
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        if (isset(this->filters[name])) {
            return this->filters[name];
        }

        var callback, pattern, filter, count, matches;
        let count = 0;
        let matches = [];

    	for pattern, filter in this->filters {
            let pattern = str_replace("\\*", "(.*?)", preg_quote(pattern, "#"), count);

            if (count) {
                if (preg_match("#^".pattern."$#", name, matches)) {
                    array_shift(matches);
                    filter->setArguments(matches);

                    return filter;
                }
            }
        }

        for callback in this->filterCallbacks {
        	let filter = call_user_func(callback, name);
            if (false !== filter) {
                return filter;
            }
        }

        return false;
    }

    public function registerUndefinedFilterCallback(callableFilter)
    {
        let this->filterCallbacks[] = callableFilter;
    }

    /**
     * Gets the registered Filters.
     *
     * Be warned that this method cannot return filters defined with registerUndefinedFunctionCallback.
     *
     * @return \TwigZ\FilterInterface[] An array of \TwigZ\FilterInterface instances
     *
     * @see registerUndefinedFilterCallback
     */
    public function getFilters()
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        return this->filters;
    }

    /**
     * Registers a Test.
     *
     * @param string|\TwigZ\SimpleTest             $name The test name or a \TwigZ\SimpleTest instance
     * @param \TwigZ\TestInterface|\TwigZ\SimpleTest $test A \TwigZ\TestInterface instance or a \TwigZ\SimpleTest instance
     */
    public function addTest(name, test = null)
    {
        if (!(name instanceof \TwigZ\SimpleTest) && (!(test instanceof \TwigZ\SimpleTest) || test instanceof \TwigZ\TestInterface)) {
            throw new \LogicException("A test must be an instance of \\TwigZ\\TestInterface or \\TwigZ\\SimpleTest");
        }

        if (name instanceof \TwigZ\SimpleTest) {
            let test = name;
            let name = test->getName();
        }

        if (this->extensionInitialized) {
            throw new \LogicException(sprintf("Unable to add test \"%s\" as extensions have already been initialized.", name));
        }

        this->staging->addTest(name, test);
    }

    /**
     * Gets the registered Tests.
     *
     * @return \TwigZ\TestInterface[] An array of \TwigZ\TestInterface instances
     */
    public function getTests()
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        return this->tests;
    }

    /**
     * Gets a test by name.
     *
     * @param string $name The test name
     *
     * @return \TwigZ\Test|false A \TwigZ\Test instance or false if the test does not exist
     */
    public function getTest(name)
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        if (isset(this->tests[name])) {
            return this->tests[name];
        }

        return false;
    }

    /**
     * Registers a Function.
     *
     * @param string|\TwigZ\SimpleFunction                 $name     The function name or a Twig_SimpleFunction instance
     * @param \TwigZ\FunctionInterface|\TwigZ\SimpleFunction $function A \TwigZ\FunctionInterface instance or a \TwigZ\SimpleFunction instance
     */
    public function addFunction(name, simpleFunction = null)
    {
        if (!(name instanceof \TwigZ\SimpleFunction) && (!(simpleFunction instanceof \TwigZ\SimpleFunction) || simpleFunction instanceof \TwigZ\FunctionInterface)) {
            throw new \LogicException("A function must be an instance of \\TwigZ\\FunctionInterface or \\TwigZ\\SimpleFunction");
        }

        if (name instanceof \TwigZ\SimpleFunction) {
            let simpleFunction = name;
            let name = simpleFunction->getName();
        }

        if (this->extensionInitialized) {
            throw new \LogicException(sprintf("Unable to add function \"%s\" as extensions have already been initialized.", name));
        }

        this->staging->addFunction(name, simpleFunction);
    }

    /**
     * Get a function by name.
     *
     * Subclasses may override this method and load functions differently;
     * so no list of functions is available.
     *
     * @param string $name function name
     *
     * @return \TwigZ\Function|false A \TwigZ\Function instance or false if the function does not exist
     */
    public function getFunction(name)
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        if (isset(this->functions[name])) {
            return this->functions[name];
        }
        var callback, pattern, simpleFunction, count, matches;
        let count = 0;
        let matches = [];

        for pattern, simpleFunction in this->functions {
            let pattern = str_replace("\\*", "(.*?)", preg_quote(pattern, "#"), count);

            if (count) {
                if (preg_match("#^".pattern."$#", name, matches)) {
                    array_shift(matches);
                    simpleFunction->setArguments(matches);

                    return simpleFunction;
                }
            }
        }

        for callback in this->functionCallbacks {
        	let simpleFunction = call_user_func(callback, name); 
            if (false !== simpleFunction) {
                return simpleFunction;
            }
        }

        return false;
    }

    public function registerUndefinedFunctionCallback(callableFunction)
    {
        let this->functionCallbacks[] = callableFunction;
    }

    /**
     * Gets registered functions.
     *
     * Be warned that this method cannot return functions defined with registerUndefinedFunctionCallback.
     *
     * @return \TwigZ\FunctionInterface[] An array of \TwigZ\FunctionInterface instances
     *
     * @see registerUndefinedFunctionCallback
     */
    public function getFunctions()
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        return this->functions;
    }

    /**
     * Registers a Global.
     *
     * New globals can be added before compiling or rendering a template;
     * but after, you can only update existing globals.
     *
     * @param string $name  The global name
     * @param mixed  $value The global value
     */
    public function addGlobal(name, value)
    {
        if (this->extensionInitialized || this->runtimeInitialized) {
            if (null === this->globals) {
                let this->globals = this->initGlobals();
            }

            /* This condition must be uncommented in Twig 2.0
            if (!array_key_exists($name, $this->globals)) {
                throw new LogicException(sprintf('Unable to add global "%s" as the runtime or the extensions have already been initialized.', $name));
            }
            */
        }

        if (this->extensionInitialized || this->runtimeInitialized) {
            // update the value
            let this->globals[name] = value;
        } else {
            this->staging->addGlobal(name, value);
        }
    }

    /**
     * Gets the registered Globals.
     *
     * @return array An array of globals
     */
    public function getGlobals()
    {
        if (!this->runtimeInitialized && !this->extensionInitialized) {
            return this->initGlobals();
        }

        if (null === this->globals) {
            let this->globals = this->initGlobals();
        }

        return this->globals;
    }

    /**
     * Merges a context with the defined globals.
     *
     * @param array $context An array representing the context
     *
     * @return array The context merged with the globals
     */
    public function mergeGlobals(array! context)
    {
        // we don't use array_merge as the context being generally
        // bigger than globals, this code is faster.
        var key, value;

        for key, value in this->getGlobals() {
            if (!array_key_exists(key, context)) {
                let context[key] = value;
            }
        }

        return context;
    }

    /**
     * Gets the registered unary Operators.
     *
     * @return array An array of unary operators
     */
    public function getUnaryOperators()
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        return this->unaryOperators;
    }

    /**
     * Gets the registered binary Operators.
     *
     * @return array An array of binary operators
     */
    public function getBinaryOperators()
    {
        if (!this->extensionInitialized) {
            this->initExtensions();
        }

        return this->binaryOperators;
    }

    public function computeAlternatives(name, items)
    {
    	array alternatives;
    	var lev, item;

        let alternatives = [];

        for item in items {
            let lev = levenshtein(name, item);
            if (lev <= strlen(name) / 3 || false !== strpos(item, name)) {
                let alternatives[item] = lev;
            }
        }
        asort(alternatives);

        return array_keys(alternatives);
    }

    protected function initGlobals()
    {
    	array globals;
    	var extGlob, extension;
        let globals = [];

        // foreach ($this->extensions as $extension) {
        for extension in this->extensions {
            let extGlob = extension->getGlobals();
            if (!is_array(extGlob)) {
                throw new UnexpectedValueException(sprintf("\"%s::getGlobals()\" must return an array of globals.", get_class(extension)));
            }

            let globals[] = extGlob;
        }

        let globals[] = this->staging->getGlobals();

        return call_user_func_array("array_merge", globals);
    }

    protected function initExtensions()
    {
        if (this->extensionInitialized) {
            return;
        }
		var extension;

        let this->extensionInitialized = true;
        let this->parsers = new \TwigZ\TokenParserBroker();
        let this->filters = [];
        let this->functions = [];
        let this->tests = [];
        let this->visitors = [];
        let this->unaryOperators = [];
        let this->binaryOperators = [];

        // foreach ($this->extensions as $extension) {
        for extension in this->extensions {
            this->initExtension(extension);
        }
        this->initExtension(this->staging);
    }

    protected function initExtension(<TwigZ\ExtensionInterface> extension)
    {
        // filters
        var 
        	filter, 
        	name,
        	simpleFunction,
        	test,
        	parser,
        	operators,
        	visitor;

        for name, filter in extension->getFilters() {
            if (name instanceof \TwigZ\SimpleFilter) {
                let filter = name;
                let name = filter->getName();
            } elseif (filter instanceof \TwigZ\SimpleFilter) {
                let name = filter->getName();
            }

            let this->filters[name] = filter;
        }

        // functions
        for name, simpleFunction in extension->getFunctions() {
            if (name instanceof \TwigZ\SimpleFunction) {
                let simpleFunction = name;
                let name = simpleFunction->getName();
            } elseif (simpleFunction instanceof \TwigZ\SimpleFunction) {
                let name = simpleFunction->getName();
            }

            let this->functions[name] = simpleFunction;
        }

        // tests
        for name, test in extension->getTests() {
            if (name instanceof \TwigZ\SimpleTest) {
                let test = name;
                let name = test->getName();
            } elseif (test instanceof \TwigZ\SimpleTest) {
                let name = test->getName();
            }

            let this->tests[name] = test;
        }

        // token parsers
        for parser in extension->getTokenParsers() {
            if (parser instanceof \TwigZ\TokenParserInterface) {
                this->parsers->addTokenParser(parser);
            } elseif (parser instanceof \TwigZ\TokenParserBrokerInterface) {
                this->parsers->addTokenParserBroker(parser);
            } else {
                throw new LogicException("getTokenParsers() must return an array of \\TwigZ\\TokenParserInterface or \\Twigz\\TokenParserBrokerInterface instances");
            }
        }

        // node visitors
        for visitor in extension->getNodeVisitors() {
            let this->visitors[] = visitor;
        }

        // operators
        let operators = extension->getOperators();
        if (operators) {
            if (2 !== count(operators)) {
                throw new \InvalidArgumentException(sprintf("\"%s::getOperators()\" does not return a valid operators array.", get_class(extension)));
            }

            let this->unaryOperators = array_merge(this->unaryOperators, operators[0]);
            let this->binaryOperators = array_merge(this->binaryOperators, operators[1]);
        }
    }

    protected function writeCacheFile(file, content)
    {
    	var dir,
    		atmkdir,
    		tmpFile,
    		atfile_put_contents,
    		atrename,
    		atchmod,
    		atcopy,
    		tildaumask
    		;
    	let atmkdir = "@mkdir";
    	let atfile_put_contents= "@file_put_contents";
    	let atrename = "@rename";
    	let atchmod = "@chmod";
    	let atcopy = "@copy";
    	let tildaumask = "0666 & ~umask()";
        let dir = dirname(file);
        if (!is_dir(dir)) {
            if (false === {atmkdir}(dir, 0777, true) && !is_dir(dir)) {
                throw new \RuntimeException(sprintf("Unable to create the cache directory (%s).", dir));
            }
        } elseif (!is_writable(dir)) {
            throw new \RuntimeException(sprintf("Unable to write in the cache directory (%s).", dir));
        }

        let tmpFile = tempnam(dir, basename(file));
        if (false !== {atfile_put_contents}(tmpFile, content)) {
            // rename does not work on Win32 before 5.2.6
            if ({atrename}(tmpFile, file) || ({atcopy}(tmpFile, file) && unlink(tmpFile))) {
                {atchmod}(file, tildaumask);

                return;
            }
        }

        throw new \RuntimeException(sprintf("Failed to write cache file \"%s\".", file));
    }
}