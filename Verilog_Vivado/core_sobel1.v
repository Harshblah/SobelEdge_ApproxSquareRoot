module core_sobel1 (
    input  [7:0] p0, p1, p2, p3, p5, p6, p7, p8,  // 8-bit pixel inputs
    output [7:0] out                            // 8-bit output pixel (approx magnitude)
);

    // Compute raw Sobel gradients (11 bits signed)
    wire signed [10:0] gx, gy;
    assign gx = ((p2 - p0) + ((p5 - p3) << 1) + (p8 - p6));
    assign gy = ((p0 - p6) + ((p1 - p7) << 1) + (p2 - p8));

    // Absolute values (11-bit)
    wire [10:0] abs_gx = gx[10] ? -gx : gx;
    wire [10:0] abs_gy = gy[10] ? -gy : gy;

    // Clamp to 8-bit max (255) if above
    wire [7:0] gx8 = (abs_gx > 11'd255) ? 8'd255 : abs_gx[7:0];
    wire [7:0] gy8 = (abs_gy > 11'd255) ? 8'd255 : abs_gy[7:0];

    // Square and sum -> 16-bit radicand for sqrt module
    wire [15:0] sqx = gx8 * gx8;
    wire [15:0] sqy = gy8 * gy8;
    wire [15:0] R   = sqx + sqy;

    // Approximate magnitude via custom square-root module
    squareroot_MAHSQR_k12 sqrt_inst (
        .R        (R),    // 16-bit radicand = gx8^2 + gy8^2
        .final_op (out)   // 8-bit approximate magnitude
    );

endmodule
