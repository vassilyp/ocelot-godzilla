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

	gpu_device := sdl.CreateGPUDevice(sdl.GPUShaderFormat{.SPIRV, .MSL, .METALLIB}, true, nil)
	fmt.assertf(gpu_device != nil, "CreateGPUDevice failed: %s", sdl.GetError())
	defer sdl.DestroyGPUDevice(gpu_device)

	window_claimed := sdl.ClaimWindowForGPUDevice(gpu_device, window)
	fmt.assertf(window_claimed, "ClaimWindowForGPUDevice failed: %s", sdl.GetError())

	vertex_shader, vert_err := load_shader(
		gpu_device,
		"shaders/compiled/triangle.vert.msl",
		0,
		0,
		0,
		0,
	)
	fmt.assertf(vert_err == Error.None, "Load shader failed: %v", vert_err)

	fragment_shader, frag_err := load_shader(
		gpu_device,
		"shaders/compiled/triangle.frag.msl",
		0,
		0,
		0,
		0,
	)
	fmt.assertf(frag_err == Error.None, "Load shader failed: %v", frag_err)

	// TODO: investigate
	pipeline_create_info := sdl.GPUGraphicsPipelineCreateInfo {
		vertex_shader = vertex_shader,
		fragment_shader = fragment_shader,
		primitive_type = sdl.GPUPrimitiveType.TRIANGLELIST,
		rasterizer_state = sdl.GPURasterizerState{fill_mode = sdl.GPUFillMode.FILL},
		target_info = sdl.GPUGraphicsPipelineTargetInfo {
			num_color_targets = 1,
			color_target_descriptions = raw_data(
				[]sdl.GPUColorTargetDescription {
					{format = sdl.GetGPUSwapchainTextureFormat(gpu_device, window)},
				},
			),
		},
	}

	pipeline := sdl.CreateGPUGraphicsPipeline(gpu_device, pipeline_create_info)
	fmt.assertf(pipeline != nil, "Couldn't create pipeline: %s", sdl.GetError())
	defer sdl.ReleaseGPUGraphicsPipeline(gpu_device, pipeline)

	sdl.ReleaseGPUShader(gpu_device, vertex_shader)
	sdl.ReleaseGPUShader(gpu_device, fragment_shader)

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
		clear_color = sdl.FColor{0.0, 0.0, 0.0, 0.0},
		load_op     = .CLEAR,
		store_op    = .STORE,
	}

	render_pass := sdl.BeginGPURenderPass(command_buffer, &color_target_info, 1, nil)

	// TODO: investigate
	sdl.BindGPUGraphicsPipeline(render_pass, pipeline)
	sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0)

	sdl.EndGPURenderPass(render_pass)

	fmt.assertf(
		sdl.SubmitGPUCommandBuffer(command_buffer),
		"SubmitGPUCommandBuffer failed: %s",
		sdl.GetError(),
	)

	event: sdl.Event

	game_loop: for {
		if sdl.PollEvent(&event) {

			if event.type == .QUIT {
				break game_loop
			}

			if event.type == .KEY_DOWN {
				#partial switch event.key.scancode {
				case .ESCAPE:
					break game_loop
				}
			}
		}
	}


	sdl.Quit()
}
