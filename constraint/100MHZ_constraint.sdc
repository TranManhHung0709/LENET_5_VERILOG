# ============================================================
# CLOCK DEFINITION
# ============================================================

# Tạo clock 100 MHz (chu kỳ = 10ns)
create_clock -name clk -period 10.000 [get_ports clk]


# ============================================================
# INPUT DELAY (giả lập môi trường ngoài)
# ============================================================

# Giả sử tín hiệu input đến trễ ~2ns
set_input_delay 2.0 -clock clk [all_inputs]


# ============================================================
# OUTPUT DELAY
# ============================================================

# Giả sử output cần ổn định trong 2ns
set_output_delay 2.0 -clock clk [all_outputs]


# ============================================================
# CLOCK UNCERTAINTY (jitter margin)
# ============================================================

set_clock_uncertainty 0.2 [get_clocks clk]


# ============================================================
# FALSE PATH (reset thường không cần timing)
# ============================================================

set_false_path -from [get_ports rst_n]


# ============================================================
# REPORT (optional – tùy tool)
# ============================================================

# Sau khi compile:
# report_timing
# report_clocks