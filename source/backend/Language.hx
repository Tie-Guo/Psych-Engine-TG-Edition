package backend;

class Language {
	public static var languages:Array<String> = ['English', 'Chinese'];
	public static var defaultLanguage:String = 'English';
	
	public function font()
	{
		if (ClientPrefs.data.language == 'English')
			return Paths.font('vcr.ttf');
		else
			return Paths.font('syht.ttf');
	}
	
	public static function get()
	{
		return ClientPrefs.data.language;
	}
}