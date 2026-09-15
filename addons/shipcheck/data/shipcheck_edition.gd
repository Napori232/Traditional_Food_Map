@tool
extends RefCounted
class_name ShipCheckEdition

enum Edition {
	LITE,
	PRO
}

const CURRENT_EDITION := Edition.LITE
const VERSION := "1.0.0"


static func get_current_edition() -> Edition:
	return CURRENT_EDITION


static func get_current_edition_label() -> String:
	return get_edition_label(CURRENT_EDITION)


static func get_edition_label(edition: Edition) -> String:
	match edition:
		Edition.LITE:
			return "Lite"
		_:
			return "Pro"


static func is_pro() -> bool:
	return CURRENT_EDITION == Edition.PRO
