extends Resource
class_name PlayerState

var position: int = 0
var balance: int = 1500
var in_jail: bool = false
var bankrupt: bool = false

# BR-16: Đếm số lượt đã ngồi tù (0 = chưa vào tù hoặc vừa vào)
var jail_turns: int = 0

func update_position(new_position: int):
	position = new_position

func add_balance(amount: int):
	balance += amount

func deduct_balance(amount: int):
	balance -= amount

func set_in_jail(flag: bool):
	in_jail = flag
	if flag:
		jail_turns = 0   # reset đếm khi vào tù
	else:
		jail_turns = 0   # reset khi ra tù

func set_bankrupt(flag: bool):
	bankrupt = flag
