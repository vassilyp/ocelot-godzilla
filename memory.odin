package main

import "base:runtime"
import "core:fmt"
import "core:mem"

report_leaks :: proc(track: mem.Tracking_Allocator) {
	if len(track.allocation_map) > 0 {
		fmt.eprintf("=== %v allocations not freed ===\n", len(track.allocation_map))
		for _, entry in track.allocation_map {
			fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
		}
	}
	if len(track.bad_free_array) > 0 {
		fmt.eprintf("=== %v bad frees ===\n", len(track.bad_free_array))
		for entry in track.bad_free_array {
			fmt.eprintf("- %p @ %v\n", entry.memory, entry.location)
		}
	}
}
