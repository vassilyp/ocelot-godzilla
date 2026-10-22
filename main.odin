package main

import "core:fmt"
import SDL "vendor:sdl2"

main :: proc() {
    WINDOW_WIDTH :: 860
    WINDOW_HEIGHT :: 480


    window := SDL.CreateWindow("sdl window", SDL.WINDOWPOS_UNDEFINED,
        SDL.WINDOWPOS_UNDEFINED, WINDOW_WIDTH, WINDOW_HEIGHT, {})
    if window == nil {
        fmt.eprintln("failed to create window")
        return
    }

    renderer := SDL.CreateRenderer(window, -1, {})
    SDL.SetRenderDrawColor(renderer, 255, 255, 255, 250)
    SDL.RenderClear(renderer)
    SDL.RenderPresent(renderer)


    SDL.Delay(2000)
    SDL.DestroyWindow(window)
    SDL.DestroyRenderer(renderer)
}
