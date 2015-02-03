require('coffee-script/register');
require('colors');

global.__base = __dirname;

var path 	= require('path');
var reader 	= require( path.join( global.__base, "lib", "reader.coffee" ) )();
