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
	defer sdl.DestroyWindow(window)

	// Create GPU stuff

	// NOTE look into shadercross
	gpu_device := sdl.CreateGPUDevice(sdl.GPUShaderFormat{.SPIRV, .MSL, .METALLIB}, true, nil)
	fmt.assertf(gpu_device != nil, "CreateGPUDevice failed: %s", sdl.GetError())
	defer sdl.DestroyGPUDevice(gpu_device)

	window_claimed := sdl.ClaimWindowForGPUDevice(gpu_device, window)
	fmt.assertf(window_claimed, "ClaimWindowForGPUDevice failed: %s", sdl.GetError())

	command_buffer := sdl.AcquireGPUCommandBuffer(gpu_device)
	fmt.assertf(command_buffer != nil, "AcquireGPUCommandBuffer failed: %s", sdl.GetError())

	swapchain_texture: ^sdl.GPUTexture
	fmt.assertf(
		sdl.WaitAndAcquireGPUSwapchainTexture(
			command_buffer,
			window,
			&swapchain_texture,
			nil,
			nil,
		),
		"WaitAndAcquireGPUSwapchainTexture failed: %s",
		sdl.GetError(),
	)

	color_target_info := sdl.GPUColorTargetInfo {
		texture     = swapchain_texture,
		clear_color = sdl.FColor{0.3, 0.6, 0.5, 1.0},
		load_op     = sdl.GPULoadOp.CLEAR,
		store_op    = sdl.GPUStoreOp.STORE,
	}

	render_pass := sdl.BeginGPURenderPass(command_buffer, &color_target_info, 1, nil)
	sdl.EndGPURenderPass(render_pass)

	fmt.assertf(
		sdl.SubmitGPUCommandBuffer(command_buffer),
		"SubmitGPUCommandBuffer failed: %s",
		sdl.GetError(),
	)

	event: sdl.Event

	game_loop: for {
		if sdl.PollEvent(&event) {

			if event.type == sdl.EventType.QUIT {
				break game_loop
			}

			if event.type == sdl.EventType.KEY_DOWN {
				#partial switch event.key.scancode {
				case .ESCAPE:
					break game_loop
				}
			}
		}
	}

	sdl.Quit()
}
