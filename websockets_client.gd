extends Node
var socket = WebSocketPeer.new()
var previousState : int = -1;

signal newPacketReceived(packet: PackedByteArray);
signal stateChanged(previousState: int,state: int);
signal connecting(socket : WebSocketPeer);
signal closing(socket : WebSocketPeer);
signal closed(socket : WebSocketPeer);
signal unknownState(socket : WebSocketPeer);

# Called when the node enters the scene tree for the first time.
func _ready():
    stateChanged.connect(stateLogger);
    newPacketReceived.connect(packetLogger);
    newPacketReceived.connect(packetToDictionary);
    pass;

func stateToString(state: int) -> String:
    var result = "";
    if(state == 0):
        result = "Connecting";
        pass;
    elif(state == 1):
        result = "Open";
        pass;
    elif(state == 2):
        result = "Closing";
        pass;
    elif(state == 3):
        result = "Closed";
        pass;
    else:
        result = "Unknown";
        pass;
    return result;
func connectToServer(hostname: String, port: int) -> void:
    var websocket_url = "ws://%s:%d" % [hostname, port]
    var err = socket.connect_to_url(websocket_url);
    if err:
        print("Error while connecting to the server:",err);
    pass;
func sendPacket(outgoingPacket: Dictionary) -> void:
    var state = socket.get_ready_state();
    if(state == WebSocketPeer.STATE_OPEN):
        var e : Error = socket.send_text(JSON.stringify(outgoingPacket));
        if e:
            print("Error:",e);
    else:
        var p = outgoingPacket;
        var s = stateToString(state);
        print("Could not send a packet due to a websocket state. packet:[%s], socketState:[%s]" % [p,s]);
    pass;
func stateLogger(prevState:int,currState:int):
    var ps : String = stateToString(prevState);
    var cs : String = stateToString(currState);
    print("State changed from [",ps,"] to [",cs,"].");
    pass;
func packetLogger(packet: PackedByteArray):
    print("New packet received. Packet:",packet);
    pass;
func stateHandler(state: int):
    if(previousState != state):
        stateChanged.emit(previousState,state);
        previousState = state;
        pass;
    pass;
func packetHandler(state: int, available_packet_count: int):
    if(state == WebSocketPeer.STATE_CONNECTING):
        print("Connecting to the server ...");
        connecting.emit();
        pass
    elif(state == WebSocketPeer.STATE_OPEN):
        if(available_packet_count > 0):
            var packet: PackedByteArray = socket.get_packet();
            newPacketReceived.emit(packet);
            pass;
        pass;
    elif(state == WebSocketPeer.STATE_CLOSING):
        print("Connection closing.");
        closing.emit();
        pass;
    elif(state == WebSocketPeer.STATE_CLOSED):
        closed.emit(socket);
        var code = socket.get_close_code();
        var reason = socket.get_close_reason();
        print("WebSocket closed with code [%d], reason: [%s]" % [code, reason]);
        set_process(false);
        pass;
    else:
        unknownState.emit();
        pass;
    pass;
static func packetToDictionary(packet: PackedByteArray) -> Dictionary:
    var result = JSON.parse_string(packet.get_string_from_utf8()) as Dictionary;
    return result;

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
    socket.poll();
    var state = socket.get_ready_state();
    var available_packet_count: int = socket.get_available_packet_count();
    stateHandler(state);
    packetHandler(state,available_packet_count);
    pass;
