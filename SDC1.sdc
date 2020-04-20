create_clock -name MCLK -period 14.9012 [get_ports {MCLK}]
create_generated_clock -name INT_CLK -source [get_ports {MCLK}] -divide_by 64 [get_nets {PRESCALER|Q_INT[6]}]
create_generated_clock -name SEQ_CLK -source [get_nets {PRESCALER|Q_INT[6]}] -divide_by 34 [get_nets {SEQUENCE_COUNTER|Q_INT[5]}]