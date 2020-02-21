module texted;

import utils.misc;


/// Returns: true if a character can be displayed
public bool canDisplay(char c){
	// TODO implement
	return true;
}

/// Returns: true if all characters in a string can be displayed
public bool canDisplay(string s){
	foreach (c; s){
		if (!canDisplay(c))
			return false;
	}
	return true;
}