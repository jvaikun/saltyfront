extends Spatial

func update_sign(status):
	$Viewport/Body/Deploy.visible = (status == "deploy")
	$Viewport/Body/Ready.visible = (status == "ready")
