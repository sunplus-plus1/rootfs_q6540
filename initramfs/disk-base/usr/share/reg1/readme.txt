lreg [a|b] [group_num]
  ex.
  lreg b 1
  read b chip group 1 , dump chip b group 1 all 32 offset value (4 byte/offset)

wreg [a|b] [group_num] [offset_num] [set_value]
  ex.
  wreg b 1 2 0x00000000 
  write b chip group 1 offset 2 value 0x00000000