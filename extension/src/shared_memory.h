#ifndef SHAREDMEMORY_H
#define SHAREDMEMORY_H

#include <godot_cpp/classes/node.hpp>

using namespace godot;

class SharedMemory : public Node {
	GDCLASS(SharedMemory, Node)

	protected:
		static void _bind_methods();
	
	public:
		SharedMemory();
		~SharedMemory();
};

#endif