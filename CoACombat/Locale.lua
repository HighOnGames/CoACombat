-- Locale.lua
-- Single-locale (enUS) for v1. Codex: to localise, replace this table lookup
-- pattern with a per-GetLocale() branch.

local L = {}

L["ADDON_NAME"]        = "CoA Combat"
L["PREFIX"]            = "|cff33ccffCoA Combat:|r "

L["STATE_ON"]          = "action mode |cff44ff44ON|r"
L["STATE_OFF"]         = "action mode |cffff5555OFF|r"

L["ERR_COMBAT"]        = "Can't change bindings while in combat. Try again after."
L["ERR_UNKNOWN_CMD"]   = "Unknown command. Type /coacombat help."
L["ERR_NO_ARG"]        = "Missing argument. Type /coacombat help."

L["HELP_HEADER"]       = "Slash commands:"
L["HELP_LINES"] = {
	"|cffffff00/coacombat|r                       status",
	"|cffffff00/coacombat on|off|toggle|r         switch action mode",
	"|cffffff00/coacombat lmb <command>|r         remap left mouse (e.g. ACTIONBUTTON1)",
	"|cffffff00/coacombat rmb <command>|r         remap right mouse",
	"|cffffff00/coacombat mmb <command>|r         remap middle mouse (blank to clear)",
	"|cffffff00/coacombat interact <key>|r        key that fires INTERACTMOUSEOVER (default E)",
	"|cffffff00/coacombat bind <key> <command>|r  arbitrary key -> command while mouselook is on",
	"|cffffff00/coacombat unbind <key>|r          drop a custom bind",
	"|cffffff00/coacombat reticle show|hide|r     toggle the crosshair",
	"|cffffff00/coacombat reticle size <px>|r     resize the crosshair",
	"|cffffff00/coacombat pause|r                 release mouselook until next click",
	"|cffffff00/coacombat macros|r                print reticle-cast macro templates",
	"|cffffff00/coacombat reset|r                 restore defaults (out of combat)",
	"",
	"Command grammar is whatever SetMouselookOverrideBinding accepts, e.g.:",
	"|cff88ccffACTIONBUTTON1..12|r bar 1  |cff88ccffMULTIACTIONBAR1..4BUTTON1..12|r bars 2-5",
	"|cff88ccffINTERACTMOUSEOVER|r talk/loot at crosshair  |cff88ccffSTARTATTACK|r auto-attack",
	"|cff88ccffJUMP|r  |cff88ccffTOGGLEAUTORUN|r  |cff88ccffSITORSTAND|r  |cff88ccffCAMERAZOOMIN|r  |cff88ccffCAMERAZOOMOUT|r",
}

L["STATUS_LMB"]        = "  LMB -> %s"
L["STATUS_RMB"]        = "  RMB -> %s"
L["STATUS_MMB"]        = "  MMB -> %s"
L["STATUS_INTERACT"]   = "  Interact key: %s (INTERACTMOUSEOVER)"
L["STATUS_EXTRA"]      = "  Custom: %s -> %s"
L["STATUS_RETICLE_ON"] = "  Reticle: shown (%dpx)"
L["STATUS_RETICLE_OFF"]= "  Reticle: hidden"

L["BOUND"]             = "Bound %s -> %s"
L["UNBOUND"]           = "Cleared %s"
L["INVALID_KEY"]       = "Not a recognised key: %s"
L["DEFAULTS_RESTORED"] = "Defaults restored."

L["MACRO_HEADER"]      = "Reticle-cast macro templates (drop into /macro):"
L["MACRO_DAMAGE"]      = "|cffffff00/cast [@mouseover,harm,nodead][@target,harm,nodead][] SpellName|r"
L["MACRO_HEAL"]        = "|cffffff00/cast [@mouseover,help,nodead][@target,help,nodead][@player] SpellName|r"
L["MACRO_AOE"]         = "|cffffff00/cast SpellName|r  (ground-target: place the targeting circle manually; @cursor is not supported on stock 3.3.5a)"
L["MACRO_INTERACT"]    = "Interaction: use your configured INTERACTMOUSEOVER key; /click InteractButton is not provided."

L.ERR_MOUSELOOK_API = "This client does not provide mouselook bindings. Action mode was disabled."
L.BINDING_FAILED = "Could not bind %s; check the key and action command."
L.ENABLE_DEFERRED = "Action mode will start after combat, when its bindings can be installed."
L.INTERACT_HINT = "Press %s to interact (INTERACTMOUSEOVER)."
L.ASSIST_HELP = "assist on|off or assist radius <20-300>. Aiming cue only; use Tab to select an enemy."
L.AIM_CUE = "Aim: %s (use Tab if needed)"
L.PRESET_MISSING = "No preset with that name."
L.PRESET_EMPTY = "No presets saved for this character."
L.PRESET_SAVED = "Preset saved: %s"
L.PRESET_LOADED = "Preset loaded: %s"
L.PRESET_HELP = "preset save|load|delete <name>, preset list, or preset spec <1|2> <name|off>. Names are one word."
L.OPT_ENABLED = "Enable action camera"
L.OPT_RETICLE = "Show crosshair"
L.OPT_ASSIST = "Show nearby enemy aiming cue"
L.OPT_LMB = "Left mouse action"
L.OPT_RMB = "Right mouse action"
L.OPT_MMB = "Middle mouse action"
L.OPT_INTERACT = "Interact key"
L.OPT_APPLY = "Apply bindings"
L.OPT_SIZE = "Crosshair size"
L.OPT_OPACITY = "Opacity"
L.OPT_COLOR_MODE = "Colour vision preset"
L.OPT_PRESET = "Preset name"
L.OPT_SAVE = "Save preset"
L.OPT_LOAD = "Load preset"
L.OPT_HINT = "Presets belong to this character. Map specs with /cac preset spec 1 <name> or 2 <name>.\nBinding changes during combat apply when combat ends. Aiming cues do not select targets."
L.OPT_UNAVAILABLE = "Options are unavailable; use /cac help."
L.CAMERA_SETTINGS = "Camera"
L.CROSSHAIR_SETTINGS = "Crosshair"
L.CROSSHAIR_HINT = "Every design uses the exact screen centre as its aim point. Asymmetric shapes grow around that fixed pivot."
L.RESTART_REQUIRED = "New addon files have not loaded. Fully exit Ascension and reopen it; /reload cannot discover newly added files on this client."
L.RETICLE_RESTART = "The selected texture has not loaded; showing the standard crosshair. Fully exit Ascension and reopen it to load new crosshair files."
L.CAMERA_ENABLED = "Use RPG camera while action mode is on"
L.CAMERA_ANGLE = "Camera angle"
L.CAMERA_DISTANCE = "Distance multiplier"
L.CAMERA_HEIGHT = "Camera height"
L.CAMERA_TRANSITION = "Transition seconds"
L.CAMERA_HEADBOB = "Head bob"
L.CAMERA_ENEMY = "Focus enemy target"
L.CAMERA_INTERACT = "Focus interactable NPC"
L.CAMERA_TRAVEL_FORMS = "Use mounted settings in travel / flight forms"
L.CAMERA_RECALL = "Remember wheel zoom"
L.CAMERA_ZOOM = "Zoom distance"
L.CAMERA_STATE_FOOT = "On foot"
L.CAMERA_STATE_MOUNTED = "Mounted"
L.CAMERA_STATE_COMBAT = "Combat"
L.CAMERA_HINT = "Adjust angle, distance and height to match your character. Use the mouse wheel for character size.\nZoom recall is enabled only on clients with a camera-zoom readout. /cac off restores previous camera settings."
L.CAMERA_UNSUPPORTED = "This build does not expose the Ascension action camera controls. Mouse lock and reticle remain available."
L.CAMERA_RPG_READY = "RPG camera and triangular reticle selected. Use /cac on to start."
L.CAMERA_STATUS = "Ascension RPG camera profile: %s. /cac camera options opens settings."
L.CAMERA_HELP = "camera on|off|rpg|options; camera speed <0-3>; camera profile <foot|mounted|combat> <angle|distance|height|enemy|interact|headbob|zoom|recall> <value|on|off>."
table.insert(L.HELP_LINES, "/coacombat camera rpg|on|off|options - RPG framing; camera speed <seconds>")
table.insert(L.HELP_LINES, "/coacombat reticle style triangle|cross|dot|plus|stacked|diagonal|curved|tbar")
table.insert(L.HELP_LINES, "/coacombat reticle opacity <10-100>; reticle color normal|redgreen|blueyellow|contrast|mono")
table.insert(L.HELP_LINES, "/coacombat options - open settings")
table.insert(L.HELP_LINES, "/coacombat assist on|off|radius <px> - nearby enemy cue")
table.insert(L.HELP_LINES, "/coacombat preset save|load|delete <name>; preset list; preset spec <1|2> <name|off>")

-- Translated camera/settings/preset messages, with enUS fallback for
-- command reference and macro explanations on every other locale.
local translations = {
	deDE = {
		STATE_ON = "Aktionsmodus |cff44ff44AN|r", STATE_OFF = "Aktionsmodus |cffff5555AUS|r",
		ERR_COMBAT = "Tastenänderungen werden nach dem Kampf übernommen.",
		ERR_NO_ARG = "Fehlendes oder ungültiges Argument. /cac help zeigt die Befehle.",
		ERR_UNKNOWN_CMD = "Unbekannter Befehl. /cac help zeigt die Befehle.",
		ERR_MOUSELOOK_API = "Dieser Client unterstützt keine Kameratasten. Aktionsmodus deaktiviert.",
		BINDING_FAILED = "%s konnte nicht gebunden werden; Taste und Befehl prüfen.",
		INTERACT_HINT = "%s drücken zum Interagieren (INTERACTMOUSEOVER).",
		ASSIST_HELP = "assist on|off oder assist radius <20-300>. Zielhilfe zeigt nur einen Hinweis; Tab wählt ein Ziel.",
		AIM_CUE = "Zielhilfe: %s (bei Bedarf Tab)",
		ENABLE_DEFERRED = "Aktionsmodus startet nach dem Kampf, sobald die Tasten eingerichtet sind.",
		PRESET_MISSING = "Keine Vorlage mit diesem Namen.", PRESET_EMPTY = "Keine Vorlagen für diesen Charakter gespeichert.",
		PRESET_SAVED = "Vorlage gespeichert: %s", PRESET_LOADED = "Vorlage geladen: %s",
		PRESET_HELP = "preset save|load|delete <Name>, preset list oder preset spec <1|2> <Name|off>. Namen ohne Leerzeichen.",
		OPT_ENABLED = "Aktionskamera aktivieren", OPT_RETICLE = "Fadenkreuz anzeigen", OPT_ASSIST = "Zielhilfe für nahe Gegner anzeigen",
		OPT_LMB = "Linke Maustaste", OPT_RMB = "Rechte Maustaste", OPT_MMB = "Mittlere Maustaste", OPT_INTERACT = "Interaktionstaste",
		OPT_APPLY = "Tasten anwenden", OPT_SIZE = "Fadenkreuzgröße", OPT_PRESET = "Vorlagenname", OPT_SAVE = "Speichern", OPT_LOAD = "Laden",
		OPT_HINT = "Vorlagen gelten für diesen Charakter. Zuweisung: /cac preset spec 1 <Name> oder 2 <Name>.\nTastenänderungen gelten nach dem Kampf. Die Zielhilfe wählt kein Ziel.",
		OPT_UNAVAILABLE = "Einstellungen nicht verfügbar; /cac help verwenden.", DEFAULTS_RESTORED = "Standardeinstellungen wiederhergestellt.",
	},
	frFR = {
		STATE_ON = "mode action |cff44ff44ACTIVÉ|r", STATE_OFF = "mode action |cffff5555DÉSACTIVÉ|r",
		ERR_COMBAT = "Les raccourcis seront appliqués après le combat.",
		ERR_NO_ARG = "Argument manquant ou invalide. Tapez /cac help.", ERR_UNKNOWN_CMD = "Commande inconnue. Tapez /cac help.",
		ERR_MOUSELOOK_API = "Ce client ne gère pas les raccourcis de caméra. Mode action désactivé.",
		BINDING_FAILED = "Impossible d'associer %s ; vérifiez la touche et la commande.",
		INTERACT_HINT = "Appuyez sur %s pour interagir (INTERACTMOUSEOVER).",
		ASSIST_HELP = "assist on|off ou assist radius <20-300>. Indication visuelle seulement ; Tab sélectionne une cible.",
		AIM_CUE = "Visée : %s (Tab si nécessaire)",
		ENABLE_DEFERRED = "Le mode action démarrera après le combat, une fois les raccourcis installés.",
		PRESET_MISSING = "Aucun profil de ce nom.", PRESET_EMPTY = "Aucun profil enregistré pour ce personnage.",
		PRESET_SAVED = "Profil enregistré : %s", PRESET_LOADED = "Profil chargé : %s",
		PRESET_HELP = "preset save|load|delete <nom>, preset list ou preset spec <1|2> <nom|off>. Noms sans espaces.",
		OPT_ENABLED = "Activer la caméra d'action", OPT_RETICLE = "Afficher le réticule", OPT_ASSIST = "Indiquer les ennemis proches du réticule",
		OPT_LMB = "Clic gauche", OPT_RMB = "Clic droit", OPT_MMB = "Clic central", OPT_INTERACT = "Touche d'interaction",
		OPT_APPLY = "Appliquer", OPT_SIZE = "Taille du réticule", OPT_PRESET = "Nom du profil", OPT_SAVE = "Enregistrer", OPT_LOAD = "Charger",
		OPT_HINT = "Profils propres à ce personnage. Associer : /cac preset spec 1 <nom> ou 2 <nom>.\nLes raccourcis changent après le combat. L'indication ne sélectionne aucune cible.",
		OPT_UNAVAILABLE = "Options indisponibles ; utilisez /cac help.", DEFAULTS_RESTORED = "Réglages par défaut rétablis.",
	},
}
local locale = GetLocale and GetLocale() or "enUS"
for key, value in pairs(translations[locale] or {}) do L[key] = value end

BINDING_HEADER_COACOMBAT = L.ADDON_NAME
BINDING_NAME_COACOMBAT_TOGGLE = L.OPT_ENABLED
BINDING_NAME_COACOMBAT_PAUSE = locale == "deDE" and "Kamera pausieren" or locale == "frFR" and "Mettre la caméra en pause" or "Release camera until next world click"
BINDING_NAME_COACOMBAT_RETICLE_TOGGLE = L.OPT_RETICLE
table.insert(L.HELP_LINES, "/coacombat targeting on|off|debug - switch aimed enemy on action-slot presses")

CoACombatLocale = L
