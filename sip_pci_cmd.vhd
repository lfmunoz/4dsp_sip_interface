--------------------------------------------------------------------------------
-- file name : sip_pci_cmd.vhd
--
-- author    : e. barhorst
--
-- company   : 4dsp
--
-- item      : number
--
-- units     : entity       -sip_pci_cmd
--             arch_itecture - arch_sip_pci_cmd
--
-- language  : vhdl
--
--------------------------------------------------------------------------------
-- description
-- ===========
--
--
-- notes:
--------------------------------------------------------------------------------
--
--  disclaimer: limited warranty and disclaimer. these designs are
--              provided to you as is.  4dsp specifically disclaims any
--              implied warranties of merchantability, non-infringement, or
--              fitness for a particular purpose. 4dsp does not warrant that
--              the functions contained in these designs will meet your
--              requirements, or that the operation of these designs will be
--              uninterrupted or error free, or that defects in the designs
--              will be corrected. furthermore, 4dsp does not warrant or
--              make any representations regarding use or the results of the
--              use of the designs in terms of correctness, accuracy,
--              reliability, or otherwise.
--
--              limitation of liability. in no event will 4dsp or its
--              licensors be liable for any loss of data, lost profits, cost
--              or procurement of substitute goods or services, or for any
--              special, incidental, consequential, or indirect damages
--              arising from the use or operation of the designs or
--              accompanying documentation, however caused and on any theory
--              of liability. this limitation will apply even if 4dsp
--              has been advised of the possibility of such damage. this
--              limitation shall apply not-withstanding the failure of the
--              essential purpose of any limited remedies herein.
--
--      from
-- ver  pcb mod    date      changes
-- ===  =======    ========  =======
--
-- 0.0    0        19-01-2009        new version
--
----------------------------------------------
--
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
-- specify libraries.
--------------------------------------------------------------------------------

library  ieee ;
use ieee.std_logic_unsigned.all ;
use ieee.std_logic_misc.all ;
use ieee.std_logic_arith.all ;
use ieee.std_logic_1164.all ;

--------------------------------------------------------------------------------
-- entity declaration
--------------------------------------------------------------------------------
entity sip_pci_cmd  is

port
(
   pci_clk                       :in  std_logic;                    --modle is synchronous to this clock
   reset                         :in std_logic;
   --command if
   cmd_clk_in                    :in  std_logic;
   out_cmd                       :out std_logic_vector(63 downto 0);
   out_cmd_val                   :out std_logic;
   in_cmd                        :in  std_logic_vector(63 downto 0);
   in_cmd_val                    :in  std_logic;

   fw_cmd_clk                    : in std_logic;
   fw_cmd                        :out std_logic_vector(31 downto 0);
   fw_cmd_val                    :out std_logic;
   fw_incmd                      :in std_logic_vector(31 downto 0);
   fw_incmd_val                  :in std_logic;
	--dma control signals
	dma_loop_back_en					:out std_logic;
	dma_isim_en 						:out std_logic;
	dma_osim_en 						:out std_logic;
	dma_blackhole_en 				   :out std_logic;
	dma_data_gen_en 				   :out std_logic;
	dma_wr_error						:in std_logic;
	dma_rd_error						:in std_logic;
   --register interface

   pci_in_data                   :in  std_logic_vector(31 downto 0);--caries the input register data
   pci_in_dval                   :in  std_logic;                    --the input data is valid
   pci_wr_addr                   :in  std_logic_vector(8 downto 0); --address for the PCI  write
   pci_rd_addr                   :in  std_logic_vector(8 downto 0); --address for the PCI read
   pci_out_data                  :out std_logic_vector(31 downto 0);--requested register data is placed on this bus
   pci_out_req                   :in  std_logic;                    --pulse to requested data

   pci_mbx_int                   :out std_logic;                     --int is asserted upon receipt of an mailbox 2 host
   cmd_mbx_int                   :out std_logic                      --int is asserted upon receipt of an read ack

   );
end entity sip_pci_cmd  ;

--------------------------------------------------------------------------------
-- arch_itecture declaration
--------------------------------------------------------------------------------
architecture arch_sip_pci_cmd   of sip_pci_cmd  is

-----------------------------------------------------------------------------------
--constant declarations
-----------------------------------------------------------------------------------
constant cmd_mbx     :std_logic_vector(3 downto 0) :=x"0";
constant cmd_rd      :std_logic_vector(3 downto 0) :=x"2";
constant cmd_wr      :std_logic_vector(3 downto 0) :=x"1";
constant cmd_rd_ack  :std_logic_vector(3 downto 0) :=x"4";
--register addresses
constant addr_cmd2pci_lsb  :std_logic_vector(8 downto 0) :='0' & x"41"; --register address for the lsb of the command to PCI register
constant addr_cmd2pci_msb  :std_logic_vector(8 downto 0) :='0' & x"43"; --register address for the lsb of the command to PCI register
constant addr_pci2cmd_lsb  :std_logic_vector(8 downto 0) :='0' & x"40"; --register address for the lsb of the command to PCI register
constant addr_pci2cmd_msb  :std_logic_vector(8 downto 0) :='0' & x"42"; --register address for the lsb of the command to PCI register
constant addr_pci_mbx      :std_logic_vector(8 downto 0) :='0' & x"0D"; --register address for the PCi mailbox

constant addr_boarddiag1  :std_logic_vector(8 downto 0) :='0' & x"14"; --register address for the lsb of the command to PCI register
constant addr_boarddiag2  :std_logic_vector(8 downto 0) :='0' & x"1E"; --register address for the lsb of the command to PCI register
constant addr_boarddiag3  :std_logic_vector(8 downto 0) :='0' & x"44"; --register address for the lsb of the command to PCI register
constant addr_sourcedest  :std_logic_vector(8 downto 0) :='0' & x"0F"; --register address for the lsb of the command to PCI register
constant addr_fwsize      :std_logic_vector(8 downto 0) :='0' & x"09"; --register address for the lsb of the command to PCI register
constant addr_userrom     :std_logic_vector(8 downto 0) :='0' & x"15"; --register address for the lsb of the command to PCI register
constant addr_ublaze_status   :std_logic_vector(8 downto 0) :='0' & x"50"; --register address for the lsb of the command to PCI register
constant addr_ublaze_id       :std_logic_vector(8 downto 0) :='0' & x"51"; --register address for the lsb of the command to PCI register

type std2d_32b is array(natural range<>) of std_logic_vector(31 downto 0);
constant nb_regs             :integer :=8;


-----------------------------------------------------------------------------------
--signal declarations
-----------------------------------------------------------------------------------
signal registers           :std2d_32b(nb_regs-1 downto 0);
signal out_reg             :std_logic_vector(31 downto 0):=(others=>'0');
signal out_reg_val         :std_logic;
signal out_reg_addr        :std_logic_vector(27 downto 0):=(others=>'0');
signal in_reg              :std_logic_vector(31 downto 0):=(others=>'0');
signal in_reg_val          :std_logic;
signal in_reg_req          :std_logic;
signal in_reg_addr         :std_logic_vector(27 downto 0):=(others=>'0');
signal out_reg_val_ack     :std_logic;
signal wr_ack              :std_logic;
signal cmd2pci_reg_lsb     :std_logic_vector(31 downto 0):=(others=>'0');
signal cmd2pci_reg_msb     :std_logic_vector(63 downto 32):=(others=>'0');
signal pci2cmd_reg_lsb     :std_logic_vector(31 downto 0):=(others=>'0');
signal pci2cmd_reg_msb     :std_logic_vector(63 downto 32):=(others=>'0');
signal pci_mbx_out_data    :std_logic_vector(31 downto 0):=(others=>'0');
signal out_cmd_sig         :std_logic_vector(63 downto 0):=(others=>'0');
signal in_cmd_reg          :std_logic_vector(63 downto 0):=(others=>'0');
signal out_cmd_val_sig     :std_logic;
signal int_out_cmd         :std_logic_vector(63 downto 0):=(others=>'0');
--signal fw_cmd_sig         :std_logic_vector(63 downto 0);
--signal fw_cmd_val_sig     :std_logic;
signal int_out_cmd_val     :std_logic;
signal in_reg_addr_sig     :std_logic_vector(27 downto 0):=(others=>'0');
signal cmd_always_ack      : std_logic;
signal in_cmd_val_pciclk   :std_logic;
--signal fw_cmd_val_sig_pipe :std_logic_vector(15 downto 0);
--signal fw_cmd_select       :std_logic;
signal board_diagnostics1  :std_logic_vector(31 downto 0);
signal board_diagnostics2  :std_logic_vector(31 downto 0);
signal board_diagnostics3  :std_logic_vector(31 downto 0);
signal userrom             :std_logic_vector(31 downto 0);
signal ublaze_status       :std_logic_vector(31 downto 0);
signal ublaze_id           :std_logic_vector(31 downto 0);

signal cmd_addr            :std_logic_vector(27 downto 0);
signal cmd_cmd             :std_logic_vector(3 downto 0);
--signal fw_cmd_val_pci_clk  :std_logic;
--signal fw_incmd_val_pciclk  :std_logic;
-----------------------------------------------------------------------------------
--component declarations
-----------------------------------------------------------------------------------
component  pulse2pulse
port (
   in_clk      :in std_logic;
   out_clk     :in std_logic;
   rst         :in std_logic;
   pulsein     :in std_logic;
   inbusy      :out std_logic;
   pulseout    :out std_logic
   );
end component;

--********************************************************************************
begin
--********************************************************************************

-----------------------------------------------------------------------------------
--component instantiations
-----------------------------------------------------------------------------------
p2p0:  pulse2pulse
port map
   (
      in_clk      =>cmd_clk_in ,
      out_clk     =>pci_clk,
      rst         =>reset,
      pulsein     =>in_cmd_val ,
      inbusy      =>open,
      pulseout    =>in_cmd_val_pciclk
   );
p2p1:  pulse2pulse
port map
   (
      in_clk      =>pci_clk,
      out_clk     =>cmd_clk_in,
      rst         =>reset,
      pulsein     =>out_cmd_val_sig ,
      inbusy      =>open,
      pulseout    =>out_cmd_val
   );

--p2p2:  pulse2pulse
--port map
--   (
--      in_clk      =>pci_clk,
--      out_clk     =>fw_cmd_clk,
--      rst         =>reset,
--      pulsein     =>fw_cmd_val_pci_clk ,
--      inbusy      =>open,
--      pulseout    =>fw_cmd_val
--   );
--p2p3:  pulse2pulse
--port map
--   (
--      in_clk      =>fw_cmd_clk ,
--      out_clk     =>pci_clk,
--      rst         =>reset,
--      pulsein     =>fw_incmd_val ,
--      inbusy      =>open,
--      pulseout    =>fw_incmd_val_pciclk
--   );
--
i_stellar_cmd: entity work.stellar_cmd
generic map (
   start_addr                    =>x"0000000",
   stop_addr                     =>x"0000007"
)
port map (
   reset                         =>reset,
   --command if
   clk_cmd                       =>pci_clk,
   out_cmd                       =>int_out_cmd,
   out_cmd_val                   =>int_out_cmd_val,
   in_cmd                        =>out_cmd_sig,
   in_cmd_val                    =>out_cmd_val_sig,
   cmd_always_ack                =>cmd_always_ack,
   --register interface
   clk_reg                       =>pci_clk,
   out_reg                       =>out_reg,
   out_reg_val_ack               =>out_reg_val_ack,
   out_reg_val                   =>out_reg_val,
   out_reg_addr                  =>out_reg_addr,
   in_reg                        =>in_reg,
   wr_ack                        =>wr_ack,
   in_reg_val                    =>in_reg_val,
   in_reg_req                    =>in_reg_req,
   in_reg_addr                   =>in_reg_addr,
   mbx_in_reg                    => (others=>'0'),   
   mbx_in_val                    => '0'

);
-----------------------------------------------------------------------------------
--synchronous processes
-----------------------------------------------------------------------------------

pci_in_proc: process(pci_clk )
begin
   if(pci_clk'event and pci_clk='1') then

      --register lsb of the command packet
      if (pci_in_dval = '1' and pci_wr_addr =addr_pci2cmd_lsb ) then
         pci2cmd_reg_lsb <= pci_in_data;
      end if;
      --register msb of the command packet
      if (pci_in_dval = '1' and pci_wr_addr =addr_pci2cmd_msb ) then
         pci2cmd_reg_msb <= pci_in_data;
         out_cmd_sig         <= pci_in_data & pci2cmd_reg_lsb;
      end if;


------if(pci_in_dval='1' and pci_wr_addr=addr_boarddiag1) then --board info 1
------   fw_cmd_sig <= cmd_wr & conv_std_logic_vector(0, 28) & pci_in_data;
------   fw_cmd_val_sig <= '1';
------elsif(pci_in_dval='1' and pci_wr_addr=addr_boarddiag2) then  --board info 2
------   fw_cmd_sig <= cmd_wr & conv_std_logic_vector(1, 28) & pci_in_data;
------   fw_cmd_val_sig <= '1';
------elsif(pci_in_dval='1' and pci_wr_addr=addr_boarddiag3) then --board info 3
------   fw_cmd_sig <= cmd_wr & conv_std_logic_vector(2, 28) & pci_in_data;
------   fw_cmd_val_sig <= '1';
------elsif(pci_in_dval='1' and pci_wr_addr=addr_sourcedest) then  --source destination updated
------   fw_cmd_sig <= cmd_wr & conv_std_logic_vector(3, 28) & pci_in_data;
------   fw_cmd_val_sig <= '1';
------elsif(pci_in_dval='1' and pci_wr_addr=addr_fwsize) then  --FW update size
------   fw_cmd_sig <= cmd_wr & conv_std_logic_vector(4, 28) & pci_in_data;
------   fw_cmd_val_sig <= '1';
------elsif(pci_in_dval='1' and pci_wr_addr=addr_userrom) then  --user rom
------   fw_cmd_sig <= cmd_wr & conv_std_logic_vector(5, 28) & pci_in_data;
------   fw_cmd_val_sig <= '1';
------elsif(fw_cmd_val_sig_pipe(14)='1') then  --the seccond part of the cmd packet
------   fw_cmd_sig <=  fw_cmd_sig(31 downto 0) & fw_cmd_sig(63 downto 32);
------else
------   fw_cmd_val_sig <= '0';
------end if;
------
------fw_cmd_val_sig_pipe <= fw_cmd_val_sig_pipe(14 downto 0) & fw_cmd_val_sig;
------
------


      --transmit the command upon receipt of the msb
      if (pci_in_dval = '1' and pci_wr_addr =addr_pci2cmd_msb ) then
         out_cmd_val_sig <= '1';
      else
         out_cmd_val_sig <= '0';
      end if;
   end if;
end process;

int_proc: process(pci_clk, reset )
begin
   if(pci_clk'event and pci_clk='1') then
      if (reset='1') then
         pci_mbx_out_data     <=(others=>'0');
         pci_mbx_int          <='0';
         cmd2pci_reg_lsb      <=(others=>'0');
         cmd2pci_reg_msb      <=(others=>'0');
         cmd_mbx_int          <= '0';
         --fw_cmd_select        <= '0';
         --ublaze_status        <=(others=>'0');
         --ublaze_id            <=(others=>'0');
         --board_diagnostics3   <=(others=>'0');
         --userrom              <=(others=>'0');

         cmd_addr             <=(others=>'0');
         cmd_cmd              <=(others=>'0');
      else
         --when we receive a mailbox command packet we need to write to the FPGA to PCI mailbox register
         --this will cause a mailbox interrupt to the host.
         if (in_cmd_val_pciclk = '1' and in_cmd_reg(63 downto 60) = cmd_mbx  ) then
            pci_mbx_out_data      <= in_cmd_reg(31 downto 0);
         elsif (int_out_cmd_val = '1' and int_out_cmd(63 downto 60) = cmd_mbx  ) then
            pci_mbx_out_data      <= int_out_cmd(31 downto 0);
         end if;

         if (in_cmd_val_pciclk = '1' and in_cmd_reg(63 downto 60) = cmd_mbx ) then
            pci_mbx_int      <='1';
         elsif (int_out_cmd_val = '1' and int_out_cmd(63 downto 60) = cmd_mbx ) then
            pci_mbx_int      <='1';
         elsif (pci_out_req = '1' and pci_rd_addr =addr_pci_mbx ) then
            pci_mbx_int      <='0';
         end if;

         --when we receive another packet we will interrupt the host to come and read the packet
         if (in_cmd_val_pciclk = '1' and in_cmd_reg(63 downto 60) /= cmd_mbx ) then
            cmd_mbx_int <= '1';
         elsif (int_out_cmd_val = '1' and int_out_cmd(63 downto 60) /= cmd_mbx ) then
            cmd_mbx_int <= '1';
         elsif (pci_out_req = '1' and pci_rd_addr =addr_cmd2pci_lsb ) then
            cmd_mbx_int <= '0';
         end if;
         if (in_cmd_val_pciclk = '1' and in_cmd_reg(63 downto 60) /= cmd_mbx ) then
            cmd2pci_reg_msb   <= in_cmd_reg(63 downto 32);
            cmd2pci_reg_lsb   <= in_cmd_reg(31 downto 0);
         elsif (int_out_cmd_val = '1' and int_out_cmd(63 downto 60) /= cmd_mbx ) then
            cmd2pci_reg_msb   <= int_out_cmd(63 downto 32);
            cmd2pci_reg_lsb   <= int_out_cmd(31 downto 0);
         end if;


         -- --receive the flash status registers
         -- if (fw_incmd_val_pciclk='1')then
         --   fw_cmd_select <= not fw_cmd_select;
         -- end if;
         --
         -- if (fw_incmd_val_pciclk='1' and fw_cmd_select ='1' and cmd_addr = 0 and cmd_cmd= cmd_wr)then
         --   board_diagnostics1 <= fw_incmd;
         -- end if;
         --
         -- if (fw_incmd_val_pciclk='1' and fw_cmd_select ='1' and cmd_addr = 1 and cmd_cmd= cmd_wr)then
         --   board_diagnostics2 <= fw_incmd;
         -- end if;
         --
         -- if (fw_incmd_val_pciclk='1' and fw_cmd_select ='1' and cmd_addr = 2 and cmd_cmd= cmd_wr)then
         --   board_diagnostics3 <= fw_incmd;
         -- end if;
         --
         -- if (fw_incmd_val_pciclk='1' and fw_cmd_select ='1' and cmd_addr = 5 and cmd_cmd= cmd_wr)then
         --   userrom <= fw_incmd;
         -- end if;
         --
         -- if (fw_incmd_val_pciclk='1' and fw_cmd_select ='1' and cmd_addr = 6 and cmd_cmd= cmd_wr)then
         --   ublaze_status <= fw_incmd;
         -- end if;
         --
         -- if (fw_incmd_val_pciclk='1' and fw_cmd_select ='1' and cmd_addr = 7 and cmd_cmd= cmd_wr)then
         --   ublaze_id <= fw_incmd;
         -- end if;
         --
         --
         -- if (fw_incmd_val_pciclk='1' and fw_cmd_select ='0' )then
         --   cmd_addr <= fw_incmd(27 downto 0);
         --   cmd_cmd <= fw_incmd(31 downto 28);
         -- end if;


      end if;
   end if;
end process;




in_reg_proc: process(pci_clk, reset )
begin
   if(pci_clk'event and pci_clk='1') then
      if (reset = '1') then
         for i in 0 to nb_regs-1 loop
            registers(i) <= (others=>'0');
             wr_ack      <= '0';
         end loop;
      else
         -- Write acknowledge
         if (out_reg_val_ack = '1') then
           wr_ack     <= '1';
         else
           wr_ack     <= '0';
         end if;    

         for i in 0 to nb_regs-1 loop
            if ((out_reg_val = '1'  or out_reg_val_ack = '1') and out_reg_addr = i) then
               registers(i) <= out_reg;
            end if;
         end loop;

         --assign default values
         registers(0) <=x"BEEFDEAF";
         registers(1) <=x"DEADBEEF";
         registers(2) <=x"01234567";
         --acknoledge the requested register
         in_reg_val 		 <= in_reg_req;
   		registers(3)(5) <= dma_wr_error;
   		registers(3)(6) <= dma_rd_error;
   end if;
   end if;
end process;
cmd_reg_proc: process(cmd_clk_in )
begin
   if(cmd_clk_in'event and cmd_clk_in='1') then
      if(in_cmd_val = '1') then
         in_cmd_reg <= in_cmd;
      end if;
   end if;
end process;
cmd_reg2_proc: process(pci_clk )
begin
   if(pci_clk'event and pci_clk='1') then
      if(out_cmd_val_sig = '1') then
         out_cmd           <= out_cmd_sig;
      end if;

   end if;
end process;
-----------------------------------------------------------------------------------
--asynchronous processes
-----------------------------------------------------------------------------------
outmux_proc: process(cmd2pci_reg_lsb, pci_rd_addr)
begin
   case pci_rd_addr is
      when addr_cmd2pci_lsb   => pci_out_data <= cmd2pci_reg_lsb;
      when addr_cmd2pci_msb   => pci_out_data <= cmd2pci_reg_msb;
      when addr_pci2cmd_lsb   => pci_out_data <= pci2cmd_reg_lsb;
      when addr_pci2cmd_msb   => pci_out_data <= pci2cmd_reg_msb;
      when addr_pci_mbx       => pci_out_data <= pci_mbx_out_data;
      --when addr_boarddiag1    => pci_out_data <= board_diagnostics1(31 downto 8) & x"10" ;--hard code CPLD version to 1.0
      --when addr_boarddiag2    => pci_out_data <= board_diagnostics2;
      --when addr_boarddiag3    => pci_out_data <= board_diagnostics3;
      --when addr_userrom       => pci_out_data <= userrom;
      --when addr_ublaze_status => pci_out_data <= ublaze_status;
      --when addr_ublaze_id     => pci_out_data <= ublaze_id;


      when others             => pci_out_data <= pci2cmd_reg_msb;
   end case;
end process;
-----------------------------------------------------------------------------------
--asynchronous mapping
-----------------------------------------------------------------------------------
--map the requested register register
in_reg <= registers(conv_integer(in_reg_addr));
--fw_cmd            <= fw_cmd_sig(31 downto 0);
--fw_cmd_val_pci_clk        <= fw_cmd_val_sig or fw_cmd_val_sig_pipe(15);


dma_loop_back_en	<= registers(3)(0);
dma_isim_en 		<= registers(3)(1);
dma_osim_en 		<= registers(3)(2);
dma_blackhole_en 	<= registers(3)(3);
dma_data_gen_en 	<= registers(3)(4);
cmd_always_ack    <= registers(3)(7);
end architecture arch_sip_pci_cmd   ; -- of sip_pci_cmd

