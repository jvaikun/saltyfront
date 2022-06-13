extends Spatial

func update_sign(status):
	$Body/Deploy.visible = (status == "deploy")
	$Body/Ready.visible = (status == "ready")
