extends Node

const WebsocketClient = preload("res://websockets_client.gd")

@onready var websocketClient = WebsocketClient.new();
@onready var chatBox = get_node("Chatbox");

# Called when the node enters the scene tree for the first time.
func _ready():
    chatBox.broadcastChat.connect(post);
    websocketClient.newPacketReceived.connect(packetReceiver);
    websocketClient.closed.connect(onClosedConnection);
    
    add_child(websocketClient);
    websocketClient.connectToServer("127.0.0.1",8081);
    pass;

func onClosedConnection(socket : WebSocketPeer):
    var code = socket.get_close_code();
    var reason = socket.get_close_reason();
    print("WebSocket closed with code %d, reason %s Clean: %s" % [code, reason, code != -1]);
    #get_tree().quit(); <- Closes the client
    pass;
func packetReceiver(packet: PackedByteArray):
    var parsedData : Dictionary = WebsocketClient.packetToDictionary(packet);
    print("Received server data: ", parsedData);
    packetSorter(parsedData);
    pass;
func packetSorter(parsedData : Dictionary):
    if(parsedData.get("chat")):
      chatBox.add_message(parsedData);
      pass;
    if(parsedData.get("rattata")):
      print("Ritz rats");
      pass;
    pass;
func post(dictionary: Dictionary):
    websocketClient.sendPacket(dictionary);
    pass;
