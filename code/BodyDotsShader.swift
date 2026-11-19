/// The shader for `BodyMetalView`. It is compiled when the app starts, because a `.metal` file would
/// need Xcode's separate Metal Toolchain download on every Mac that builds the app.
enum BodyDotsShader {
    static let source = #"""
    #include <metal_stdlib>
    using namespace metal;

    // One dot, laid out exactly like BodyDot in LiftLogCore.
    struct Dot {
        float2 position;
        float radius;
        uint slot;
    };

    struct Uniforms {
        float2 size;        // the view in points
        float pixelsPerPoint;
        float4 colors[23];  // premultiplied, one per colour slot, and the ink flood
    };

    struct Corner {
        float4 position [[position]];
        float2 offset;      // from the dot's centre, in pixels
        float radius;       // in pixels
        float4 color;
    };

    vertex Corner dotVertex(uint corner [[vertex_id]],
                            uint instance [[instance_id]],
                            const device Dot *dots [[buffer(0)]],
                            constant Uniforms &uniforms [[buffer(1)]]) {
        const float2 corners[4] = { float2(-1, -1), float2(1, -1), float2(-1, 1), float2(1, 1) };
        const Dot dot = dots[instance];
        // One extra pixel around the circle for its soft edge.
        const float reach = dot.radius + 1.0 / uniforms.pixelsPerPoint;
        const float2 offset = corners[corner] * reach;
        const float2 point = dot.position + offset;

        Corner out;
        out.position = float4(point.x / uniforms.size.x * 2 - 1, 1 - point.y / uniforms.size.y * 2, 0, 1);
        out.offset = offset * uniforms.pixelsPerPoint;
        out.radius = dot.radius * uniforms.pixelsPerPoint;
        out.color = uniforms.colors[dot.slot];
        return out;
    }

    fragment float4 dotFragment(Corner in [[stage_in]]) {
        // How much of this pixel the circle covers: a one-pixel ramp across the edge.
        const float coverage = saturate(in.radius - length(in.offset) + 0.5);
        return in.color * coverage;
    }
    """#
}
