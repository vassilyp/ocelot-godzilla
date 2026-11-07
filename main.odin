package main

import "core:fmt"
import "core:mem"
import sdl "vendor:sdl3"

WINDOW_WIDTH :: 860
WINDOW_HEIGHT :: 480

Vector3 :: struct {
	x, y, z: f32,
}

Vertex :: struct {
	position: Vector3,
}

main :: proc() {
	when ODIN_DEBUG {
		track: mem.Tracking_Allocator
		mem.tracking_allocator_init(&track, context.allocator)
		defer mem.tracking_allocator_destroy(&track)

		context.allocator = mem.tracking_allocator(&track)
		defer report_leaks(track)
	}

	// GPU SETUP

	init_ok := sdl.Init({.VIDEO})
	fmt.assertf(init_ok, "Init failed: %s", sdl.GetError())
	defer sdl.Quit()

	metadataSet := sdl.SetAppMetadata("Ocelot", "version 0.0", "ocelot")
	fmt.assertf(metadataSet, "couldn't set metadata: %s", sdl.GetError())

	window := sdl.CreateWindow(
		"SDL Window",
		WINDOW_WIDTH,
		WINDOW_HEIGHT,
		sdl.WindowFlags{.RESIZABLE},
	)
	fmt.assertf(window != nil, "CreateWindow failed: %s", sdl.GetError())
	defer sdl.DestroyWindow(window)


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

	vertex_buffer_description := []sdl.GPUVertexBufferDescription {
		{slot = 0, pitch = size_of(Vertex), input_rate = .VERTEX},
	}
	vertex_attributes := []sdl.GPUVertexAttribute {
		{location = 0, buffer_slot = 0, format = .FLOAT3, offset = 0},
	}
	color_target_descriptions := []sdl.GPUColorTargetDescription {
		{format = sdl.GetGPUSwapchainTextureFormat(gpu_device, window)},
	}

	pipeline_create_info := sdl.GPUGraphicsPipelineCreateInfo {
		vertex_shader = vertex_shader,
		fragment_shader = fragment_shader,
		vertex_input_state = {
			vertex_buffer_descriptions = raw_data(vertex_buffer_description),
			num_vertex_buffers = 1,
			vertex_attributes = raw_data(vertex_attributes),
			num_vertex_attributes = 1,
		},
		primitive_type = .TRIANGLELIST,
		rasterizer_state = {fill_mode = sdl.GPUFillMode.FILL},
		target_info = sdl.GPUGraphicsPipelineTargetInfo {
			num_color_targets = 1,
			color_target_descriptions = raw_data(color_target_descriptions),
		},
	}

	pipeline := sdl.CreateGPUGraphicsPipeline(gpu_device, pipeline_create_info)
	fmt.assertf(pipeline != nil, "Couldn't create pipeline: %s", sdl.GetError())
	defer sdl.ReleaseGPUGraphicsPipeline(gpu_device, pipeline)

	sdl.ReleaseGPUShader(gpu_device, vertex_shader)
	sdl.ReleaseGPUShader(gpu_device, fragment_shader)


	// "GAME CODE"

	event: sdl.Event

	clear_color := sdl.FColor{0.0, 0.0, 0.0, 1.0}

	// vertex buffer code (copy pass)

	vertices := [3]Vertex {
		{position = {x = -1.0, y = -1.0, z = 0.0}},
		{position = {x = 0.0, y = 1.0, z = 0.0}},
		{position = {x = 1.0, y = -1.0, z = 0.0}},
	}

	vertices_size := u32(size_of(vertices))

	vertex_buffer := sdl.CreateGPUBuffer(gpu_device, {usage = {.VERTEX}, size = vertices_size})
	fmt.assertf(vertex_buffer != nil, "couldn't create gpu buffer: %s", sdl.GetError())
	defer sdl.ReleaseGPUBuffer(gpu_device, vertex_buffer)

	transfer_buffer := sdl.CreateGPUTransferBuffer(
		gpu_device,
		{usage = .UPLOAD, size = vertices_size},
	)
	fmt.assertf(transfer_buffer != nil, "couldn't create transfer buffer: %s", sdl.GetError())

	transfer_buffer_address := sdl.MapGPUTransferBuffer(gpu_device, transfer_buffer, false)
	fmt.assertf(transfer_buffer_address != nil, "couldn't map transfer buffer: %s", sdl.GetError())
	mem.copy(transfer_buffer_address, raw_data(vertices[:]), int(vertices_size))
	sdl.UnmapGPUTransferBuffer(gpu_device, transfer_buffer)

	command_buffer := sdl.AcquireGPUCommandBuffer(gpu_device)
	fmt.assertf(command_buffer != nil, "couldn't acquire command buffer: %s", sdl.GetError())

	copy_pass := sdl.BeginGPUCopyPass(command_buffer)
	fmt.assertf(copy_pass != nil, "couldn't begin copy pass: %s", sdl.GetError())

	sdl.UploadToGPUBuffer(
		copy_pass,
		{transfer_buffer = transfer_buffer, offset = 0},
		{buffer = vertex_buffer, offset = 0, size = vertices_size},
		false,
	)
	sdl.EndGPUCopyPass(copy_pass)
	fmt.assertf(
		sdl.SubmitGPUCommandBuffer(command_buffer),
		"couldn't submit command buffer: %s",
		sdl.GetError(),
	)

	sdl.ReleaseGPUTransferBuffer(gpu_device, transfer_buffer)

	// end vertex buffer code

	game_loop: for {
		for sdl.PollEvent(&event) {
			if event.type == .QUIT {
				break game_loop
			}

			if event.type == .KEY_DOWN {
				#partial switch event.key.scancode {
				case .ESCAPE:
					break game_loop
				case .UP:
					clear_color = sdl.FColor{1.0, 0.0, 0.0, 1.0}
				}
			} else if event.type == .KEY_UP {
				#partial switch event.key.scancode {
				case .UP:
					clear_color = sdl.FColor{0.0, 0.0, 0.0, 1.0}
				}
			}
		}

		// render pass

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
			clear_color = clear_color,
			load_op     = .CLEAR,
			store_op    = .STORE,
		}
		render_pass := sdl.BeginGPURenderPass(command_buffer, &color_target_info, 1, nil)

		sdl.BindGPUGraphicsPipeline(render_pass, pipeline)

		bindings := []sdl.GPUBufferBinding{{buffer = vertex_buffer, offset = 0}}
		sdl.BindGPUVertexBuffers(render_pass, 0, raw_data(bindings), 1)

		sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0)
		sdl.EndGPURenderPass(render_pass)
		fmt.assertf(
			sdl.SubmitGPUCommandBuffer(command_buffer),
			"SubmitGPUCommandBuffer failed: %s",
			sdl.GetError(),
		)

		// end render pass
	}
}
