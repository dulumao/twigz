namespace TwigZ;


class Test {

	public function anotherMethod(testVar)
	{
		if !(testVar instanceof \TwigZ\SimpleFilter) {
			return false;
		}
	}

	public function leva()
	{
		var name, item, lev;
		let name = "leva";
		let item = "lev";
		let lev = levenshtein(name, item);

		echo lev;
	}


	public static function checkKey()
	{
		array a;
		var v;
		let a = [1,2,3,4,5];
		for v in a {
			echo v;
		}
	}
}
