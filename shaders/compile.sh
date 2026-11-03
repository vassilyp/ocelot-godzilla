# requires 'shadercross' to be in PATH

shadercross triangle.vert.hlsl -o compiled/triangle.vert.msl
shadercross triangle.vert.hlsl -o compiled/triangle.vert.dxil
shadercross triangle.vert.hlsl -o compiled/triangle.vert.spv

shadercross triangle.frag.hlsl -o compiled/triangle.frag.msl
shadercross triangle.frag.hlsl -o compiled/triangle.frag.dxil
shadercross triangle.frag.hlsl -o compiled/triangle.frag.spv
