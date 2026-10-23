package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"

WINDOW_WIDTH :: 860
WINDOW_HEIGHT :: 480

main :: proc() {
	context.logger = log.create_console_logger()

	metadataSet := sdl.SetAppMetadata("app name", "version 0.0", "app id")
	fmt.assertf(metadataSet, "couldn't set metadata: %s", sdl.GetError())

	window := sdl.CreateWindow("title", WINDOW_WIDTH, WINDOW_HEIGHT, sdl.WindowFlags{.RESIZABLE})
	fmt.assertf(window != nil, "CreateWindow failed: %s", sdl.GetError())

	screen_surface := sdl.GetWindowSurface(window)

	// load bmp image
	imagePath := "./example.bmp"

	// TODO: continue tutorial https://lazyfoo.net/tutorials/SDL3/01-hello-sdl3/index2.php


	sdl.Quit()
}
