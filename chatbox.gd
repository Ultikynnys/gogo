extends Control

@onready var chat_log : RichTextLabel = get_node("CanvasLayer/VBoxContainer/RichTextLabel");
@onready var input_field : LineEdit = get_node("CanvasLayer/VBoxContainer/HBoxContainer/LineEdit");

signal broadcastChat(dictionary : Dictionary);

func _ready():
    input_field.text_submitted.connect(text_entered);
    pass;
func _input(event: InputEvent):
  if event is InputEventKey and event.pressed:
    var e : InputEventKey = event;
    match e.keycode:
      KEY_ENTER:
        input_field.grab_focus();
        pass;
      KEY_ESCAPE:
        input_field.release_focus();
        pass;
  pass;
func add_message(packet: Dictionary):
  chat_log.text += packet.get("chat")+"\n";
  pass;
static func stringToDictionary(key: String, value: String) -> Dictionary:
    var result : Dictionary;
    result[key] = value;
    return result;
func text_entered(text: String):
  if len(text) > 0:
    input_field.text = ""
    var key : String = "chat";
    var value : String = text;
    var result : Dictionary = stringToDictionary(key,value);
    broadcastChat.emit(result);
    pass;
