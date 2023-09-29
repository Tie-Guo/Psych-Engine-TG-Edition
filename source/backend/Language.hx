package backend;

class Language {
	public static var languages:Array<String> = ['English', 'Chinese'];
	public static var defaultLanguage:String = 'English';
	
	public static function font()
	{
		if (get() == 'English')
			return Paths.font('vcr.ttf');
		else
			return Paths.font('syht.ttf');
	}
	
	public static function get()
	{
		return ClientPrefs.data.language;
	}
}