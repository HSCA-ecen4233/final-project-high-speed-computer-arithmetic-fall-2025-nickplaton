# Copyright 1991-2024 Mentor Graphics Corporation
# 
# Modification by Oklahoma State University
# Use with Testbench 
# James Stine, 2008
# Go Cowboys!!!!!!
#
# All Rights Reserved.
#
# THIS WORK CONTAINS TRADE SECRET AND PROPRIETARY INFORMATION
# WHICH IS THE PROPERTY OF MENTOR GRAPHICS CORPORATION
# OR ITS LICENSORS AND IS SUBJECT TO LICENSE TERMS.

# Use this run.do file to run this example.
# Either bring up ModelSim and type the following at the "ModelSim>" prompt:
#     do run.do
# or, to run from a shell, type the following at the shell prompt:
#     vsim -do run.do -c
# (omit the "-c" to see the GUI while running from the shell)

onbreak {resume}

# create library
if [file exists work] {
    vdel -all
}
vlib work

# compile source files
vlog -lint fma16.sv testbench.sv fmaadd.sv fmaalign.sv fmaexpadd.sv fmamult.sv fmasign.sv unpack.sv lzc.sv

# start and run simulation
vsim -voptargs=+acc work.tb_fma16

# Diplays All Signals recursively
# add wave -hex -r /stimulus/*
add wave -noupdate -divider -height 32 "fma16"
add wave -color gold -hex /tb_fma16/clk
add wave -hex /tb_fma16/reset
add wave -hex /tb_fma16/x
add wave -hex /tb_fma16/y
add wave -hex /tb_fma16/z
add wave -hex /tb_fma16/result
add wave -hex /tb_fma16/rexpected
add wave -noupdate -divider -height 32 "internals"
add wave -hex /tb_fma16/dut/Ze
add wave -hex /tb_fma16/dut/Zm
add wave -hex /tb_fma16/dut/Zs
add wave -hex /tb_fma16/dut/ZZero
add wave -hex /tb_fma16/dut/Zsubnorm
add wave -hex /tb_fma16/dut/Zinf
add wave -hex /tb_fma16/dut/Znan
add wave -hex /tb_fma16/dut/Zsnan

add wave -hex /tb_fma16/dut/Zunpack/Xenonz
add wave -hex /tb_fma16/dut/Zunpack/Xf
add wave -hex /tb_fma16/dut/Zunpack/Xfzero

add wave -hex /tb_fma16/dut/Pe
add wave -hex /tb_fma16/dut/Pm
add wave -hex /tb_fma16/dut/Ps
add wave -hex /tb_fma16/dut/Am
add wave -hex /tb_fma16/dut/ASticky
add wave -hex /tb_fma16/dut/KillProd

add wave -hex /tb_fma16/dut/align/Acnt
add wave -hex /tb_fma16/dut/align/KillZ
add wave -hex /tb_fma16/dut/align/Zmpresh
add wave -hex /tb_fma16/dut/align/Zmshift

add wave -hex /tb_fma16/dut/As
add wave -hex /tb_fma16/dut/InvA

add wave -hex /tb_fma16/dut/finadd/PreSum
add wave -hex /tb_fma16/dut/finadd/NegPreSum
add wave -hex /tb_fma16/dut/finadd/NegSum

add wave -hex /tb_fma16/dut/AmInv
add wave -hex /tb_fma16/dut/PmKilled
add wave -hex /tb_fma16/dut/Se
add wave -hex /tb_fma16/dut/Sm
add wave -hex /tb_fma16/dut/Ss
add wave -hex /tb_fma16/dut/Senorm
add wave -hex /tb_fma16/dut/Smnorm
add wave -hex /tb_fma16/dut/Mcnt


run -all
quit

