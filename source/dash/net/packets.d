module dash.net.packets;

enum PacketType : ubyte
{
	Login,
    Logoff,
    Whisper,
    ChangePassword,
    UploadFile,
	Data,
}

class Packet
{

}

class LoginPacket : Packet
{
	string username;
}

class LogoffPacket : Packet
{
	string username;
}

class WhisperPacket : Packet
{
	string target;
	string message;
}

class DataPacket : Packet
{
	string type;
	ubyte[] data;
}
