#ifndef NAMEDPIPE_H
#define NAMEDPIPE_H

#include <godot_cpp/classes/ref_counted.hpp>

#ifdef _WIN32
#include <Windows.h>
#else

#endif

using namespace godot;

class NamedPipe : public RefCounted {
	GDCLASS(NamedPipe, RefCounted)

	private:

#ifdef _WIN32
		HANDLE pipe;
		char *buffer;
		int buffer_size;
#else

#endif

	protected:
		static void _bind_methods();
	
	public:
		NamedPipe();
		~NamedPipe();
		bool create_buffer(int size);
		bool init(String path);
		PackedByteArray read();
		void delete_buffer();
};

#endif