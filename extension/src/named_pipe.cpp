#include "named_pipe.h"
#include "godot_cpp/variant/utility_functions.hpp"

using namespace godot;

void NamedPipe::_bind_methods() {
	ClassDB::bind_method(D_METHOD("create_buffer", "size"), &NamedPipe::create_buffer);
	ClassDB::bind_method(D_METHOD("init", "path"), &NamedPipe::init);
	ClassDB::bind_method(D_METHOD("read"), &NamedPipe::read);
}

NamedPipe::NamedPipe() {

}

NamedPipe::~NamedPipe() {

}

#ifdef _WIN32

bool NamedPipe::create_buffer(int size) {
	buffer = new char[size];
	buffer_size = size;
	return buffer != NULL;
}

bool NamedPipe::init(String path) {
	const char* path_c_str = path.ascii().get_data();
	pipe = CreateFileA(path_c_str, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING, 0, NULL);

	if (pipe == INVALID_HANDLE_VALUE) {
		return false;
	}

	DWORD dwMode = PIPE_READMODE_MESSAGE;
	return SetNamedPipeHandleState(pipe, &dwMode, NULL, NULL);
}

PackedByteArray NamedPipe::read() {
	int bytes_read;
	uint32_t message_length;
	int err = ReadFile(pipe, &message_length, 4, (DWORD*) &bytes_read, NULL);
	if (err) {
		return PackedByteArray();
	}

	PackedByteArray out = PackedByteArray();
	out.resize(message_length);
	char* internal_buffer = (char*) out._native_ptr();

	err = ReadFile(pipe, buffer, message_length - 1, (DWORD*) &bytes_read, NULL);
	if (err) {
		return PackedByteArray();
	}
	// This is so stupid. There has to be a better way
	for (int i = 0; i < bytes_read; i ++) {
		out[i] = buffer[i];
	}
	out[bytes_read] = '\xd9'; // I hate Windows, hopefully this is constant
	return out;
}

void NamedPipe::delete_buffer() {
	delete buffer;
}

#else

bool NamedPipe::create_buffer(int size) {

}

bool NamedPipe::init(String path) {

}

PackedByteArray NamedPipe::read() {

}

#endif