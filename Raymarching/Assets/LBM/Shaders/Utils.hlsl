

float2 arrowTileCenterCoord(float2 pos, float ArrowSize) {
    return (floor(pos / ArrowSize) + 0.5) * ArrowSize;
}
float lineSdf(float2 p, float2 p1, float2 p2) {
    float2 center = (p1 + p2) * 0.5;
    float len = length(p2 - p1);
    float2 dir = (p2 - p1) / len;
    float2 rel_p = p - center;
    float dist1 = abs(dot(rel_p, float2(dir.y, -dir.x)));
    float dist2 = abs(dot(rel_p, dir)) - 0.5 * len;
    return max(dist1, dist2);
}
float arrow(float2 p, float2 v, float ArrowSize) {
    // Make everything relative to the center, which may be fractional
    p -= arrowTileCenterCoord(p, ArrowSize);
    float ARROW_HEAD_ANGLE = 45.0 * PI / 180.0;
    float ARROW_HEAD_LENGTH = ArrowSize / 6.0;

    float mag_v = length(v), mag_p = length(p);

    if (mag_v > 0.0) {
        // Non-zero velocity case
        float2 dir_v = v / mag_v;

        // We can't draw arrows larger than the tile radius, so clamp magnitude.
        // Enforce a minimum length to help see direction
        mag_v = clamp(mag_v, 5., ArrowSize * 0.5);

        // Arrow tip location
        v = dir_v * mag_v;

        float shaft = lineSdf(p, v, -v);
        // Signed distance from head
        float head = min(lineSdf(p, v, 0.4 * v + 0.2 * float2(-v.y, v.x)),
            lineSdf(p, v, 0.4 * v + 0.2 * float2(v.y, -v.x)));

        return min(shaft, head);

    }
    else {
        // Signed distance from the center point
        return mag_p;
    }
}