package main

import "core:fmt"
import "core:log"
import sdl "vendor:sdl3"

WINDOW_WIDTH :: 860
WINDOW_HEIGHT :: 480

Vector3 :: struct {
	x, y, z: f64,
}

main :: proc() {
	context.logger = log.create_console_logger()

	metadataSet := sdl.SetAppMetadata("app name", "version 0.0", "app id")
	fmt.assertf(metadataSet, "couldn't set metadata: %s", sdl.GetError())

	window := sdl.CreateWindow("title", WINDOW_WIDTH, WINDOW_HEIGHT, sdl.WindowFlags{.RESIZABLE})
	fmt.assertf(window != nil, "CreateWindow failed: %s", sdl.GetError())

	// Create GPU stuff

	// NOTE look into shadercross
	gpu_device := sdl.CreateGPUDevice(sdl.GPUShaderFormat{.SPIRV, .MSL, .METALLIB}, true, nil)
	fmt.assertf(gpu_device != nil, "CreateGPUDevice failed: %s", sdl.GetError())

	window_claimed := sdl.ClaimWindowForGPUDevice(gpu_device, window)
	fmt.assertf(window_claimed, "ClaimWindowForGPUDevice failed: %s", sdl.GetError())

	triangle_vertices := [3]Vector3 {
		Vector3{0.0, 0.5, 0.0},
		Vector3{-0.5, -0.5, 0.0},
		Vector3{0.5, -0.5, 0.0},
	}

	vertex_shader_file := #load("shaders/vertex.msl")
	fragment_shader_file := #load("shaders/fragment.msl")

	vertex_shader := sdl.CreateGPUShader(
		gpu_device,
		sdl.GPUShaderCreateInfo {
			code_size = len(vertex_shader_file),
			code = raw_data(vertex_shader_file),
			entrypoint = "main0",
			format = sdl.GPUShaderFormat{.MSL},
			stage = sdl.GPUShaderStage.VERTEX,
			num_samplers = 0,
			num_storage_textures = 0,
			num_storage_buffers = 0,
			num_uniform_buffers = 0,
			props = 0,
		},
	)
	fmt.assertf(vertex_shader != nil, "CreateGPUShader failed: %s", sdl.GetError())


	sdl.Quit()
}
