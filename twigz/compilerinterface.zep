namespace TwigZ;

interface CompilerInterface
{
	public function compile(<\TwigZ\NodeInterface> node);
	public function getSource();
}

