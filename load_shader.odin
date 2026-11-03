package main

import "core:os"
import "core:path/filepath"
import sdl "vendor:sdl3"

Error :: enum {
	None,
	Bad_Filename,
	No_GPU_Format,
	Cannot_Read_File,
}

load_shader :: proc(
	device: ^sdl.GPUDevice,
	filename: string,
	sampler_count: u32,
	uniform_buffer_count: u32,
	storage_buffer_count: u32,
	storage_texture_count: u32,
) -> (
	^sdl.GPUShader,
	Error,
) {

	shader_stage: sdl.GPUShaderStage

	stage_extension := filepath.ext(filepath.stem(filename))
	switch stage_extension {
	case ".vert":
		shader_stage = .VERTEX
	case ".frag":
		shader_stage = .FRAGMENT
	case:
		return nil, .Bad_Filename
	}

	formats := sdl.GetGPUShaderFormats(device)
	format := sdl.GPUShaderFormat{.PRIVATE}
	entrypoint := ""
	switch {
	case .SPIRV in formats:
		format = {.SPIRV}
		entrypoint = "main"
	case .MSL in formats:
		format = {.MSL}
		entrypoint = "main0"
	case .DXIL in formats:
		format = {.DXIL}
		entrypoint = "main"

	case:
		return nil, .No_GPU_Format
	}

	code, err := os.read_entire_file(filename, context.temp_allocator)
	if err != nil {
		return nil, .Cannot_Read_File
	}

	shader_info := sdl.GPUShaderCreateInfo {
		code                 = raw_data(code),
		code_size            = len(code),
		format               = format,
		stage                = shader_stage,
		num_samplers         = sampler_count,
		num_storage_textures = storage_texture_count,
		num_storage_buffers  = storage_buffer_count,
		num_uniform_buffers  = uniform_buffer_count,
	}

	shader := sdl.CreateGPUShader(device, shader_info)

	free_all(context.temp_allocator)

	return shader, nil
}
