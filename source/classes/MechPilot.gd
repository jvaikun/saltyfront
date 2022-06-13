extends Reference
class_name MechPilot

var id : String = "0"
var name : String = "Default"
var face : int = 0
var melee : int = 0
var short : int = 0
var long : int = 0
var dodge : int = 0
var skill0 : String = "none"
var skill1 : String = "none"
var skill2 : String = "none"
var skill3 : String = "none"
var ai_params : Dictionary = {
	"offense":{"enemy":1.0, "allies":0.5, "cover":0.5, "repair":1.0, "splash":1.0},
	"defense":{"enemy":0.5, "allies":1.0, "cover":1.0, "repair":2.0, "splash":2.0},
	"retreat":{"enemy":0.0, "allies":2.0, "cover":2.0, "repair":5.0, "splash":5.0}
}
