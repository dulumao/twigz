namespace TwigZ;

/**
 * Autoloads Twig classes.
 *
 */
class Autoloader
{
	/**
	 * Registers Twig_Autoloader as an SPL autoloader.
	 *
	 * @param bool $prepend Whether to prepend the autoloader or not.
	 */
	public static function register (prepend = false)
	{
		string className;

		let className = str_replace("\\", "\\\\", __CLASS__);
		if (PHP_VERSION_ID < 50300) {
			spl_autoload_register([className, "autoload"]);
		} else {
			spl_autoload_register([className, "autoload"], true, prepend);
		}
	}

	/**
	 * Handles autoloading of classes.
	 *
	 * @param string $class A class name.
	 */
	public static function autoload(className)
	{
		if (0 !== strpos(className, "TwigZ")) {
			return;
		}

		if (!class_exists(className)) {
			trigger_error("Unable to load class: ".className, E_USER_WARNING);
		}
	}
}