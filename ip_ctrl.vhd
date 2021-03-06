-------------------------------------------------------------------------------------
-- FILE NAME : fmc176_ctrl.vhd
--
-- AUTHOR    : Peter Kortekaas
--
-- COMPANY   : 4DSP
--
-- ITEM      : 1
--
-- UNITS     : Entity       - fmc176_ctrl
--             architecture - fmc176_ctrl_syn
--
-- LANGUAGE  : VHDL
--
-------------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- fmc176_ctrl
-- Notes: fmc176_ctrl
-------------------------------------------------------------------------------------
--  Disclaimer: LIMITED WARRANTY AND DISCLAIMER. These designs are
--              provided to you as is.  4DSP specifically disclaims any
--              implied warranties of merchantability, non-infringement, or
--              fitness for a particular purpose. 4DSP does not warrant that
--              the functions contained in these designs will meet your
--              requirements, or that the operation of these designs will be
--              uninterrupted or error free, or that defects in the Designs
--              will be corrected. Furthermore, 4DSP does not warrant or
--              make any representations regarding use or the results of the
--              use of the designs in terms of correctness, accuracy,
--              reliability, or otherwise.
--
--              LIMITATION OF LIABILITY. In no event will 4DSP or its
--              licensors be liable for any loss of data, lost profits, cost
--              or procurement of substitute goods or services, or for any
--              special, incidental, consequential, or indirect damages
--              arising from the use or operation of the designs or
--              accompanying documentation, however caused and on any theory
--              of liability. This limitation will apply even if 4DSP
--              has been advised of the possibility of such damage. This
--              limitation shall apply not-withstanding the failure of the
--              essential purpose of any limited remedies herein.
--
----------------------------------------------

-------------------------------------------------------------------------------------
-- Specified libraries
-------------------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_unsigned.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_1164.all;
library unisim;
  use unisim.vcomponents.all;

-------------------------------------------------------------------------------------
-- Entity declaration
-------------------------------------------------------------------------------------

entity stellarip_registers is
generic
(
  START_ADDR             : std_logic_vector(27 downto 0) := x"0000000";
  STOP_ADDR              : std_logic_vector(27 downto 0) := x"00000FF"
);
port (
  rst                    : in  std_logic;
  -- Command Interface
  clk_cmd                : in    std_logic;
  in_cmd_val             : in    std_logic;
  in_cmd                 : in    std_logic_vector(63 downto 0);
  out_cmd_val            : out   std_logic;
  out_cmd                : out   std_logic_vector(63 downto 0);
  cmd_busy               : out   std_logic;  
  
  reg0                  : out std_logic_vector(31 downto 0);
  reg1                  : out std_logic_vector(31 downto 0);
  
  reg2                  : in std_logic_vector(31 downto 0);
  reg3                  : in std_logic_vector(31 downto 0);
  reg4                  : in std_logic_vector(31 downto 0);
  reg5                  : in std_logic_vector(31 downto 0);
  reg6                  : in std_logic_vector(31 downto 0);

  mbx_in_reg            : in  std_logic_vector(31 downto 0);--value of the mailbox to send
  mbx_in_val            : in  std_logic                     --pulse to indicate mailbox is valid 

);
end stellarip_registers;

-------------------------------------------------------------------------------------
-- Architecture declaration
-------------------------------------------------------------------------------------
architecture fmc_ctrl_syn of stellarip_registers is

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------
constant ADDR_REG0       : std_logic_vector(31 downto 0) := x"00000000";
constant ADDR_REG1       : std_logic_vector(31 downto 0) := x"00000001";
constant ADDR_REG2       : std_logic_vector(31 downto 0) := x"00000002";
constant ADDR_REG3       : std_logic_vector(31 downto 0) := x"00000003";
constant ADDR_REG4       : std_logic_vector(31 downto 0) := x"00000004";
constant ADDR_REG5       : std_logic_vector(31 downto 0) := x"00000005";
constant ADDR_REG6       : std_logic_vector(31 downto 0) := x"00000006";
constant ADDR_REG7       : std_logic_vector(31 downto 0) := x"00000007";
constant ADDR_REG8       : std_logic_vector(31 downto 0) := x"00000008";
constant ADDR_REG9       : std_logic_vector(31 downto 0) := x"00000009";
constant ADDR_REGA       : std_logic_vector(31 downto 0) := x"0000000A";
constant ADDR_REGB       : std_logic_vector(31 downto 0) := x"0000000B";
constant ADDR_REGC       : std_logic_vector(31 downto 0) := x"0000000C";
constant ADDR_REGD       : std_logic_vector(31 downto 0) := x"0000000D";
constant ADDR_REGE       : std_logic_vector(31 downto 0) := x"0000000E";
constant ADDR_REGF       : std_logic_vector(31 downto 0) := x"0000000F";

----------------------------------------------------------------------------------------------------
-- Signals
----------------------------------------------------------------------------------------------------
signal out_reg_val       : std_logic;
signal out_reg_addr      : std_logic_vector(27 downto 0);
signal out_reg           : std_logic_vector(31 downto 0);

signal in_reg_req        : std_logic;
signal in_reg_addr       : std_logic_vector(27 downto 0);
signal in_reg_val        : std_logic;
signal in_reg            : std_logic_vector(31 downto 0);
signal out_reg_val_ack   : std_logic;
signal wr_ack            : std_logic;

signal register0         : std_logic_vector(31 downto 0);
signal register1         : std_logic_vector(31 downto 0);
signal register2         : std_logic_vector(31 downto 0);
signal register3         : std_logic_vector(31 downto 0);
signal register4         : std_logic_vector(31 downto 0);
signal register5         : std_logic_vector(31 downto 0);
signal register6         : std_logic_vector(31 downto 0);
signal register7         : std_logic_vector(31 downto 0);
signal register8         : std_logic_vector(31 downto 0);
signal register9         : std_logic_vector(31 downto 0);
signal registerA         : std_logic_vector(31 downto 0);

--*************************************************************************************************
begin
--*************************************************************************************************

reg0  <= register0;
reg1  <= register1;


----------------------------------------------------------------------------------------------------
-- Stellar Command Interface
----------------------------------------------------------------------------------------------------
stellar_cmd_inst: 
entity work.gbl_generic_cmd
generic map (
  START_ADDR   => START_ADDR,
  STOP_ADDR    => STOP_ADDR
)
port map (
  reset        => rst,

  clk_cmd      => clk_cmd,
  in_cmd_val   => in_cmd_val,
  in_cmd       => in_cmd,
  out_cmd_val  => out_cmd_val,
  out_cmd      => out_cmd,

  clk_reg      => clk_cmd,
  out_reg_val  => out_reg_val,
  out_reg_addr => out_reg_addr,
  out_reg      => out_reg,
  out_reg_val_ack   => out_reg_val_ack,

  in_reg_req   => in_reg_req,
  in_reg_addr  => in_reg_addr,
  in_reg_val   => in_reg_val,
  in_reg       => in_reg,
  wr_ack       => wr_ack,
  mbx_in_val   => mbx_in_val,
  mbx_in_reg   => mbx_in_reg
);

cmd_busy <= '0';

----------------------------------------------------------------------------------------------------
-- Registers
----------------------------------------------------------------------------------------------------
process (rst, clk_cmd)
begin
  if (rst = '1') then
    -- cmd_reg         <= (others => '0');
    in_reg_val      <= '0';
    in_reg          <= (others => '0');
    wr_ack     <= '0';
    register0   <= (others=>'0');
    register1   <= (others=>'0');


  elsif (rising_edge(clk_cmd)) then

    ------------------------------------------------------------
    -- Write
	 ------------------------------------------------------------
    
	if ((out_reg_val = '1' or out_reg_val_ack = '1') and out_reg_addr = ADDR_REG0) then
	  register0 <= out_reg;
   else
      register0 <= (others=>'0');
   end if;
    
 	if ((out_reg_val = '1' or out_reg_val_ack = '1') and out_reg_addr = ADDR_REG1) then
	  register1 <= out_reg;
   end if;   

    -- Write acknowledge
    if (out_reg_val_ack = '1') then
      wr_ack     <= '1';
    else
      wr_ack     <= '0';
    end if;    
    ------------------------------------------------------------
    -- Read
    if (in_reg_req = '1' and in_reg_addr = ADDR_REG0) then
      in_reg_val <= '1';
      in_reg     <= register0;
    elsif (in_reg_req = '1' and in_reg_addr = ADDR_REG1) then
      in_reg_val <= '1';
      in_reg     <= register1;
    elsif (in_reg_req = '1' and in_reg_addr = ADDR_REG2) then
      in_reg_val <= '1';
      in_reg     <= reg2;
    elsif (in_reg_req = '1' and in_reg_addr = ADDR_REG3) then
      in_reg_val <= '1';
      in_reg     <= reg3;
    elsif (in_reg_req = '1' and in_reg_addr = ADDR_REG4) then
      in_reg_val <= '1';
      in_reg     <= reg4;
    elsif (in_reg_req = '1' and in_reg_addr = ADDR_REG5) then
      in_reg_val <= '1';
      in_reg     <= reg5;	      
    elsif (in_reg_req = '1' and in_reg_addr = ADDR_REG6) then
      in_reg_val <= '1';
      in_reg     <= reg6;	        
    else
      in_reg_val <= '0';
      in_reg     <= in_reg;
    end if;

  end if;
end process;


--*************************************************************************************************
end fmc_ctrl_syn;
--*************************************************************************************************
