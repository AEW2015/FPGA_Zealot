#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include <xil_io.h>

#define T0BA 0x41c00000
#define T1BA 0x41c10000
#define TLR0 0x00
#define TLR1 0x10
#define TCR0 0x08
#define TCR1 0x18

#define XCLK_US_VCO_MAX 1600
#define XCLK_US_VCO_MIN 800
#define XCLK_US_M_MIN 2
#define XCLK_US_M_MAX 128
#define XCLK_US_D_MAX 106
#define XCLK_US_D_MIN 1
#define XCLK_US_O_MAX 128
#define XCLK_US_O_MIN 1

int main()
{
	init_platform();

	print("Hello World\n\r");
	Xil_Out32(T0BA+TLR0,0);
	Xil_Out32(T0BA+TLR1,0);


	Xil_Out32(T0BA+0x04,0);
	Xil_Out32(T0BA+0x14,0);


	Xil_Out32(T0BA+TLR0,0x20);
	Xil_Out32(T0BA+TLR1,0x20);

	Xil_Out32(T0BA+TLR1,0x820);
	Xil_Out32(T0BA+TLR0,0x8C0);
	u32 time_0 = Xil_In32(T0BA+TCR0);
	for (int i = 0; i<0xFFFF;i++){

	}
	u32 time_1 = Xil_In32(T0BA+TCR0);
	u32 diff_0 = time_1 - time_0;
	xil_printf("time %x %x d=%x\n\r",time_0,time_1,diff_0);


	Xil_Out32(T1BA+TLR0,0);
	Xil_Out32(T1BA+TLR1,0);


	Xil_Out32(T1BA+0x04,0);
	Xil_Out32(T1BA+0x14,0);


	Xil_Out32(T1BA+TLR0,0x20);
	Xil_Out32(T1BA+TLR1,0x20);

	Xil_Out32(T1BA+TLR1,0x820);
	Xil_Out32(T1BA+TLR0,0x8C0);
	time_0 = Xil_In32(T1BA+TCR0);
	for (int i = 0; i<0xFFFF;i++){

	}
	time_1 = Xil_In32(T1BA+TCR0);
	u32 diff_1 = time_1 - time_0;
	xil_printf("time %x %x d=%x\n\r",time_0,time_1,diff_1);
	u32 new_freq = 100*(diff_1/diff_0);
	xil_printf("new freq  %u\n\r",new_freq);


	for (u64 SetRate = 100; SetRate<=1000;SetRate+=10)
	{
		u32 m;
		u32 d;
		u32 Div;
		u64 Fvco;
		u64 Freq;
		u64 Diff;
		u64 Minerr = 1000;
		u64 VcoMin;
		u64 VcoMax;
		u32 Mmin;
		u32 Mmax;
		u32 Dmin;
		u32 Dmax;
		u32 Omin;
		u32 Omax;
		u32 PrimInClkFreq = 100;


		VcoMin = XCLK_US_VCO_MIN;
		VcoMax = XCLK_US_VCO_MAX;
		Mmin = XCLK_US_M_MIN;
		Mmax = XCLK_US_M_MAX;
		Dmin = XCLK_US_D_MIN;
		Dmax = XCLK_US_D_MAX;
		Omin = XCLK_US_O_MIN;
		Omax = XCLK_US_O_MAX;


		u32 m_final;
		u32 d_final;
		u32 Div_final;


		for (m = Mmin; m <= Mmax; m++) {
			for (d = Dmin; d <= Dmax; d++) {
				Fvco = PrimInClkFreq  * m / d;
				if ( Fvco >= VcoMin && Fvco <= VcoMax ) {

					for (Div = Omin; Div <= Omax; Div++ ) {
						Freq = Fvco/Div;

						if (Freq > SetRate) {
							Diff = Freq - SetRate;
						} else {
							Diff = SetRate - Freq;
						}
						if (Diff == 0 ) {
							m_final = m;
							d_final = d;
							Div_final = Div;
							goto next_step;
						} else if (Diff < Minerr) {
							Minerr = Diff;
							m_final = m;
							d_final = d;
							Div_final = Div;
						}

					}
				}
			}
		}
		next_step:
		xil_printf("new %x %x %x\n\r",m_final,d_final,Div_final);

#define CLK1_WIZ 0x44A00000

		u32 clk_config_0 = d_final | (m_final << 8);
		Xil_Out32(CLK1_WIZ+0x200,clk_config_0);
		Xil_Out32(CLK1_WIZ+0x208,Div_final);
		Xil_Out32(CLK1_WIZ+0x25C,0x3);

		Xil_Out32(T1BA+TLR0,0);
		Xil_Out32(T1BA+TLR1,0);


		Xil_Out32(T1BA+0x04,0);
		Xil_Out32(T1BA+0x14,0);


		Xil_Out32(T1BA+TLR0,0x20);
		Xil_Out32(T1BA+TLR1,0x20);

		Xil_Out32(T1BA+TLR1,0x820);
		Xil_Out32(T1BA+TLR0,0x8C0);
		time_0 = Xil_In32(T1BA+TCR0);
		for (int i = 0; i<0xFFFF;i++){

		}
		time_1 = Xil_In32(T1BA+TCR0);
		u32 diff_2 = time_1 - time_0;
		xil_printf("time %x %x d=%x\n\r",time_0,time_1,diff_2);
		new_freq = ((100*diff_2)/diff_0);
		xil_printf("new freq  %u\n\r",new_freq);


		u32 test_count = 0;
		for (int j = 0; j<10;j++){
			for (int i = 0; i <0x200000;i+=4){
				Xil_Out32(0xC0000000+i,0x55555555);
			}

			for (int i = 0; i <0x200000;i+=4){
				if (Xil_In32(0xC0000000+i)==0x55555555)
				{
					test_count++;
				}
			}

			for (int i = 0; i <0x200000;i+=4){
				Xil_Out32(0xC0000000+i,0xAAAAAAAA);
			}
			for (int i = 0; i <0x200000;i+=4){
				if (Xil_In32(0xC0000000+i)==0xAAAAAAAA)
				{
					test_count++;
				}
			}

			for (int i = 0; i <0x200000;i+=4){
				Xil_Out32(0xC0000000+i,i);
			}
			for (int i = 0; i <0x200000;i+=4){
				if (Xil_In32(0xC0000000+i)==i)
				{
					test_count++;
				}
			}
		}


		xil_printf("test  0x%X \n\r",test_count);

	}


	cleanup_platform();
	return 0;
}