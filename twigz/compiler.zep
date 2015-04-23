namespace TwigZ;

/**
 * Compiles a node to PHP code.
 *
 */
class Compiler implements CompilerInterface
{
	protected lastLine;
	protected source;
	protected indentation;
	protected env;
	protected debugInfo;
	protected sourceOffset;
	protected sourceLine;
	protected filename;

	/**
	 * Constructor.
	 *
	 * @param TwigZ\Environment $env The twig environment instance
	 */
	public function __construct(<\TwigZZ\Environment> env)
	{
		let this->env = env;
		let this->debugInfo = [];
	}

	public function getFilename()
	{
		return this->filename;
	}

	/**
	 * Returns the environment instance related to this compiler.
	 *
	 * @return \TwigZ\Environment The environment instance
	 */
	public function getEnvironment()
	{
		return this->env;
	}

	/**
	 * Gets the current PHP code after compilation.
	 *
	 * @return string The PHP code
	 */
	public function getSource()
	{
		return this->source;
	}

	/**
	 * Compiles a node.
	 *
	 * @param Twig_NodeInterface $node        The node to compile
	 * @param int                $indentation The current indentation
	 *
	 * @return \Twig\Compiler The current compiler instance
	 */
	public function compile(<\TwigZ\NodeInterface> node, int! indentation = 0)
	{
		let this->lastLine = null;
		let this->source = "";
		let this->debugInfo = [];
		let this->sourceLine = 0;
		let this->indentation = indentation;

		if (node instanceof \TwigZ\Node\Module) {
			let this->filename = node->getAttribute("filename");
		}

		node->compile(this);

		return this;
	}

	public function subcompile(<\TwigZ\NodeInterface> node, raw = true)
	{
		if (false === raw) {
			this->addIndentation();
		}

		node->compile(this);

		return this;
	}

	/**
	 * Adds a raw string to the compiled code.
	 *
	 * @param string $string The string
	 *
	 * @return Twig_Compiler The current compiler instance
	 */
	public function raw(compileString)
	{
		let this->source .= compileString;

		return this;
	}

	/**
	 * Writes a string to the compiled code by adding indentation.
	 *
	 * @return Twig_Compiler The current compiler instance
	 */
	public function write()
	{
		var strings, v;

		let strings = func_get_args();
		for v in strings {
			this->addIndentation();
			let this->source .= v;
		}

		return this;
	}

	/**
	 * Appends an indentation to the current PHP code after compilation.
	 *
	 * @return Twig_Compiler The current compiler instance
	 */
	public function addIndentation()
	{
		let this->source .= str_repeat(" ", this->indentation * 4);

		return this;
	}

	/**
	 * Adds a quoted string to the compiled code.
	 *
	 * @param string $value The string
	 *
	 * @return Twig_Compiler The current compiler instance
	 */
	public function createString(value)
	{
		let this->source .= sprintf("\"%s\"", addcslashes(value, "\\0\\t\\\"\\$\\\\"));

		return this;
	}

	/**
	 * Returns a PHP representation of a given value.
	 *
	 * @param mixed $value The value to convert
	 *
	 * @return \Twig\Compiler The current compiler instance
	 */
	public function repr(var someValue)
	{
		var locale, first;

		if (is_int(someValue) || is_float(someValue)) {
			let locale = setlocale(LC_NUMERIC, 0);
			if (false !== locale) {
				setlocale(LC_NUMERIC, 'C');
			}

			this->raw(someValue);

			if (false !== locale) {
				setlocale(LC_NUMERIC, locale);
			}
		} elseif (null === someValue) {
			this->raw("null");
		} elseif (is_bool(someValue)) {
			this->raw(someValue ? "true" : "false");
		} elseif (is_array(someValue)) {
			var k, v;
			this->raw("array(");
			let first = true;
			for k, v in someValue {
				if !(first) {
					this->raw(", ");
				}
				let first = false;
				this->repr(k);
				this->raw(" => ");
				this->repr(v);
			}
			//this->raw(")");
		} else {
			this->createString(someValue);
		}

		return this;
	}

	/**
	 * Adds debugging information.
	 *
	 * @param Twig_NodeInterface $node The related twig node
	 *
	 * @return Twig_Compiler The current compiler instance
	 */
	public function addDebugInfo(<\TwigZ\NodeInterface> node)
	{
		if (node->getLine() != this->lastLine) {
			this->{"write"}(sprintf("// line %d\\n", node->getLine()));

			// when mbstring.func_overload is set to 2
			// mb_substr_count() replaces substr_count()
			// but they have different signatures!
			if (((int) ini_get("mbstring.func_overload")) & 2) {
				// this is much slower than the "right" version
				let this->sourceLine += mb_substr_count(mb_substr(this->source, this->sourceOffset), "\\n");
			} else {
				let this->sourceLine += substr_count(this->source, "\\n", this->sourceOffset);
			}
			let this->sourceOffset = strlen(this->source);
			let this->debugInfo[this->sourceLine] = node->getLine();

			let this->lastLine = node->getLine();
		}

		return this;
	}

	public function getDebugInfo()
	{
		ksort(this->debugInfo);

		return this->debugInfo;
	}

	/**
	 * Indents the generated code.
	 *
	 * @param int $step The number of indentation to add
	 *
	 * @return Twig_Compiler The current compiler instance
	 */
	public function indent(step = 1)
	{
		let this->indentation += step;

		return this;
	}

	/**
	 * Outdents the generated code.
	 *
	 * @param int $step The number of indentation to remove
	 *
	 * @return Twig_Compiler The current compiler instance
	 *
	 * @throws LogicException When trying to outdent too much so the indentation would become negative
	 */
	public function outdent(step = 1)
	{
		if (this->indentation < step) {
			throw new \LogicException("Unable to call outdent() as the indentation would become negative");
		}

		let this->indentation -= step;

		return this;
	}

	public function getVarName()
	{
		return sprintf("__internal_%s", hash("sha256", uniqid(mt_rand(), true), false));
	}

}