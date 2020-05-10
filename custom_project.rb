require 'gosu'
require_relative 'circle'

MAP_WIDTH = 600
MAP_HEIGHT = 600
CUSTOMER_FREQUENCY = 0.01
CUSTOMER_SPEED = 4
ACO_BREAKS = 0.009
CIRCLE_1 = Circle.new(25, 255, 255, 210)
CIRCLE_2 = Circle.new(30, 255, 255, 210)
CIRCLE_3 = Circle.new(20, 255, 255, 210)

module ACO_status
  Working = 0
  Broken = 1
end

class GameMap
  attr_accessor :width, :height, :tiles, :floor, :wall, :aco
end

class Customer
  attr_accessor :x, :y, :image, :velocity_x, :velocity_y, :direction, :radius, :speed, :is_selected, :go_to_aco_number, :item_amount, :at_aco
end

class ACO
  attr_accessor :x, :y, :image, :is_selected, :broken, :radius, :busy, :number
end

class Employee
  attr_accessor :x, :y, :image, :is_selected, :radius, :go_to_aco_number, :speed, :at_aco, :back_to_position
end

# Credit for the following class goes to: https://github.com/Dahrkael/RPG-Template-for-Ruby-Gosu/blob/master/Timer.rb
class Timer
  attr_accessor :seconds, :last_time
end

def read_game_map(filename)
  game_map = GameMap.new


  lines = File.readlines(filename).map { |line| line.chomp }
  game_map.height = lines.size
  game_map.width = lines[0].size
  game_map.floor = Gosu::Image.new("media/floor.png")
  game_map.wall = Gosu::Image.new("media/brick.png")



  game_map.tiles = Array.new(game_map.width) do |x|
    Array.new(game_map.height) do |y|
      case lines[y][x]
      when '.'
        game_map.floor
      when '#'
        game_map.wall
      when 'x'
        @aco = setup_aco(x, y)
        @all_aco << @aco
      end
    end
  end
  game_map
end

def draw_game_map(game_map)
  game_map.height.times do |y|
    game_map.width.times do |x|
      tile = game_map.tiles[x][y]

      if (tile == game_map.wall)
        game_map.wall.draw(x * 20 - 20, y * 30, 0)
      end

      if (tile == game_map.floor)
        game_map.floor.draw(x * 20, y * 30, 0)
      end

      if (tile == game_map.aco)
        index = 0
        while index < @all_aco.length
          @all_aco[index].image.draw(@all_aco[index].x * 20, @all_aco[index].y * 25, 1)
          index += 1
        end
      end
    end
  end
end


def setup_customer(customer, x, y)

  customer = Customer.new()
  customer.x, customer.y = x, y
  customer.image = Gosu::Image.new("media/customer.png")
  customer.velocity_x = 0
  customer.velocity_y = 0
  customer.direction = 270
  customer.radius = 30
  customer.speed = 4
  customer.is_selected = false
  customer.go_to_aco_number = nil
  customer.item_amount = rand(1..20)
  customer.at_aco = nil

  return customer
end

def draw_customer(customer)
  if customer.y < 490 && customer.x > 300
    customer.image.draw_rot(customer.x, customer.y, 1, customer.direction)
    draw_item_amount_vertical(customer)
  elsif customer.y >= 490 && customer.x <= 300
    customer.direction = 0
    customer.image.draw_rot(customer.x, customer.y, 1, customer.direction)
    draw_item_amount_horizontal(customer)
  else
    customer.direction = 0
    customer.image.draw_rot(customer.x, customer.y, 1, customer.direction)
    draw_item_amount_horizontal(customer)
  end
end

def draw_item_amount_vertical(customer)
  rect_x = customer.x - 10
  rect_y = customer.y - 2

  if customer.item_amount >= 10
    Gosu.draw_rect(rect_x, rect_y, 25, 20, Gosu::Color::GRAY, 1, mode=:default)
    @font.draw(customer.item_amount, rect_x, rect_y, scale_x = 2, scale_y = 2, 2)
  else
    Gosu.draw_rect(rect_x, rect_y, 20, 20, Gosu::Color::GRAY, 1, mode=:default)
    @font.draw(customer.item_amount, rect_x, rect_y, scale_x = 3, scale_y = 3, 2)
  end
end

def draw_item_amount_horizontal(customer)
  rect_x = customer.x - 10
  rect_y = customer.y - 10

  if customer.item_amount >= 10
    Gosu.draw_rect(rect_x, rect_y, 25, 20, Gosu::Color::GRAY, 1, mode=:default)
    @font.draw(customer.item_amount, rect_x, rect_y, scale_x = 2, scale_y = 2, 2)
  else
    Gosu.draw_rect(rect_x, rect_y, 20, 20, Gosu::Color::GRAY, 1, mode=:default)
    @font.draw(customer.item_amount, rect_x, rect_y, scale_x = 3, scale_y = 3, 2)
  end
end

def move_customer_in_line(customer)
  if customer.y < 450
    customer.y += customer.speed
  elsif (customer.y > 450 && customer.y < 500) && (customer.x > 350)
    customer.x -= customer.speed
    customer.y += customer.speed
  elsif (customer.y >= 500) && (customer.x > 350)
    customer.x -= customer.speed
  end
end

def check_customer_collision(customers)
  @customers.dup.each do |customer1|
    @customers.dup.each do |customer2|
      if (customer1 != customer2)
        distance = Gosu.distance(customer1.x, customer1.y, customer2.x, customer2.y)
        distance_first_two = Gosu.distance(customers[0].x, customers[0].y, customers[1].x, customers[1].y)
        if (customer1.y <= 160) && (customer2.y <= 160)
          @customers.delete customer1
        else
          if (distance_first_two < customers[0].radius + customers[1].radius) && customers[0].y >= 500 && customers[1].y >= 500 && customers[1].x <= 405
            customers[0].speed = 0
            customers[1].speed = 0
            if (distance < customer1.radius + customer2.radius)
              customer1.speed = 0
              customer2.speed = 0
            end
          else
            customer1.speed = 4
            customer2.speed = 4
          end
        end
      end
    end
  end
end

def line_free (customers)
  free = true
  @customers.each do |customers|
    if customers.y < 160
      free = false
    end
  end

  return free
end

def customer_clicked(customers, leftX, topY, rightX, bottomY)

  item_clicked = 0
  index = 0
  while index < customers.length
    if (customers[index].x + customers[index].radius) > rightX && (customers[index].x - customers[index].radius) < leftX && (customers[index].y + customers[index].radius) > bottomY && (customers[index].y - customers[index].radius) < topY
      item_clicked = customers[index]
    end
    index += 1
  end

  return item_clicked

end

def highlight_customer(customers, customer)
  highlight_chosen_customer = Gosu::Image.new(CIRCLE_1, false)
  highlight_chosen_customer.draw customer.x - customer.radius, customer.y - customer.radius + 5, 0
end

def unselect_other_customers(customers)
  index = 0
  while index < customers.length
    if customers[index].is_selected == true
      customers[index].is_selected = false
    end
    index += 1
  end
end

def focus_on_customer(customers, customer_picked)
  unselect_other_customers(@customers)
  if customer_picked != 0
    customer_picked.is_selected = true
  end
end

def which_customer_selected(customers)
  index = 0

  while index < customers.length
    if customers[index].is_selected == true
      return customers[index]
    end
    index += 1
  end

  return nil

end

def setup_aco(x, y)
  aco = ACO.new()
  aco.x, aco.y = x, y
  aco.image = Gosu::Image.new("media/aco.png")
  aco.is_selected = false
  aco.broken = false
  aco.radius = 30
  aco.busy = false
  aco.number = 0

  return aco
end

def aco_clicked(all_aco, leftX, topY, rightX, bottomY)
  item_clicked = 0
  index = 0

  while index < all_aco.length
    if ((all_aco[index].x * 30) + all_aco[index].radius + 5) > rightX && ((all_aco[index].x * 30) - all_aco[index].radius + 5) < leftX && ((all_aco[index].y * 26) + all_aco[index].radius + 5) > bottomY && ((all_aco[index].y * 26) - all_aco[index].radius + 5) < topY
      item_clicked = all_aco[index]
      all_aco[index].number = index
    elsif ((all_aco[index].x * 22) + all_aco[index].radius + 5) > rightX && ((all_aco[index].x * 22) - all_aco[index].radius + 5) < leftX && ((all_aco[index].y * 26) + all_aco[index].radius + 5) > bottomY && ((all_aco[index].y * 26) - all_aco[index].radius + 5) < topY
      item_clicked = all_aco[index]
      all_aco[index].number = index
    end
    index += 1
  end

  return item_clicked
end

def focus_on_aco (all_aco, aco_picked)
  unselect_other_aco(@all_aco)
  if aco_picked != 0
    aco_picked.is_selected = true
  end
end

def unselect_other_aco(all_aco)
  index = 0
  while index < all_aco.length
    if all_aco[index].is_selected == true
      all_aco[index].is_selected = false
    end
    index += 1
  end
end

def highlight_aco(all_aco, aco)
  highlight_chosen_aco = Gosu::Image.new(CIRCLE_2, false)
  highlight_chosen_aco.draw (aco.x * 20) - 5, (aco.y * 25) + 5, 0
end

def which_aco_selected(all_aco)
  index = 0

  while index < all_aco.length
    if all_aco[index].is_selected == true
      return all_aco[index]
    end
    index += 1
  end
end

def move_customer_to_aco(customer, aco)
  if customer.go_to_aco_number != nil

    if customer.x > 100 && customer.y > 460
      customer.speed = 4
      customer.y -= customer.speed/4.5
      customer.x -= customer.speed*1.3
    end

    if customer.y > aco[customer.go_to_aco_number].y * 26 + 23  && customer.x <= 250
      customer.y -= customer.speed/2
    end

    if customer.y <= aco[customer.go_to_aco_number].y * 26 + 23
      if customer.x >= aco[customer.go_to_aco_number].x * 22
        customer.x -= customer.speed/4
        if customer.x - aco[customer.go_to_aco_number].x - aco[customer.go_to_aco_number].radius - customer.radius <= 55
          customer.speed = 0
          make_aco_busy(aco[customer.go_to_aco_number])
          customer_checking_out(customer, aco[customer.go_to_aco_number])
        end
      else
        customer.x += customer.speed/4
        if aco[customer.go_to_aco_number].x * 23 - customer.x - aco[customer.go_to_aco_number].radius - customer.radius <= 0
          customer.speed = 0
          make_aco_busy(aco[customer.go_to_aco_number])
          customer_checking_out(customer, aco[customer.go_to_aco_number])
        end
      end
    end
  end
end

def move_customer_to_exit(customer, aco)
  if customer.item_amount == 0 && customer.at_aco == false
    if customer.go_to_aco_number == 4
      if customer.x > 180
        customer.x -= CUSTOMER_SPEED
      elsif customer.x <= 180 && customer.y < 100
        customer.y += CUSTOMER_SPEED
      elsif customer.y >= 100
        customer.x -= CUSTOMER_SPEED
        pop_customer_from_screen(customer)
      end
    end
    #
    if customer.x >= aco[customer.go_to_aco_number].x * 22 && customer.y > 100 && customer.go_to_aco_number != 4
      if customer.x < 180
        customer.x += CUSTOMER_SPEED
      elsif customer.x > 180 && customer.y > 100
        customer.y -= CUSTOMER_SPEED
      end
    elsif customer.y <= 100 && customer.go_to_aco_number != 4
      customer.x -= CUSTOMER_SPEED
      istrue = pop_customer_from_screen(customer)
    end

    if customer.x <= aco[customer.go_to_aco_number].x * 22 && customer.y > 100 && customer.go_to_aco_number != 4
      if customer.x > 180
        customer.x -= CUSTOMER_SPEED
      elsif customer.x < 180 && customer.y > 100
        customer.y -= CUSTOMER_SPEED
      end
    end
  end
end

def path_picked_customer(customer, aco)
  if aco and customer
    customer.go_to_aco_number = aco.number
  end
end

def make_aco_busy(aco)
  aco.busy = true
end

def customer_checking_out(customer, aco)
  customer.at_aco = true
  if customer.item_amount > 0
    if ((Gosu.milliseconds % 1000 >= rand(0..100)) && (Gosu.milliseconds % 1000 <= rand(0..100))) && aco.broken != true
      customer.item_amount -= 1
    end
  else
    customer.at_aco = false
    aco.busy = false
  end
end

def pop_customer_from_screen(customer)
  if customer.x <= 0
    add_one_to_score
    @customers_in_aco.delete customer
  end
end

def add_one_to_score
  @score += 1
end

def draw_score
  @font_score.draw("Score: " + @score.to_s, 400, 20, 2, 1, 1, Gosu::Color::BLUE)
end

def all_aco_status(all_aco)
  status = Gosu::Image.load_tiles("media/check_and_cross.png", 25, 23)
  index = 0
  while index < all_aco.length
    if all_aco[index].broken == false
      status[ACO_status::Working].draw(all_aco[index].x * 20, all_aco[index].y * 25, 1)
    else
      status[ACO_status::Broken].draw(all_aco[index].x * 20, all_aco[index].y * 25, 1)
    end
    index += 1
  end
end

def setup_employee (employee, x, y)
  employee = Employee.new()
  employee.x, employee.y = x, y
  employee.image = Gosu::Image.new("media/employee.png")
  employee.is_selected = false
  employee.radius = 25
  employee.go_to_aco_number = nil
  employee.speed = 4
  employee.at_aco = false
  employee.back_to_position = false

  return employee
end

def draw_employee (employee)
  employee.image.draw(employee.x, employee.y, 1, 1.0, 1.0)
end

def employee_clicked (employees, leftX, topY, rightX, bottomY)
  employee_clicked = 0
  index = 0
  while index < employees.length
    if (employees[index].x + 15 + employees[index].radius) > rightX && (employees[index].x + 15 - employees[index].radius) < leftX && (employees[index].y + 20 + employees[index].radius) > bottomY && (employees[index].y + 20 - employees[index].radius) < topY
      return employees[index]
    end
    index += 1
  end

  return employee_clicked

end

def focus_on_employee(employees, employee_picked)
  unselect_other_employees(@employees)
  if employee_picked != 0
    employee_picked.is_selected = true
  end
end

def unselect_other_employees(employees)
  index = 0
  while index < employees.length
    if employees[index].is_selected == true
      employees[index].is_selected = false
    end
    index += 1
  end
end

def highlight_employee(employees, employee)
  highlight_chosen_employee = Gosu::Image.new(CIRCLE_3, false)
  highlight_chosen_employee.draw employee.x + 22 - employee.radius, employee.y + 27 - employee.radius, 0
end

def path_picked_employee(employee, aco)
  if aco and employee
    employee.go_to_aco_number = aco.number
  end
end

def move_employee_to_aco(employee, all_aco)
  if employee.go_to_aco_number != nil && employee.at_aco == false && employee.back_to_position == false

    if employee.y > all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y)
      employee.speed = 4
      employee.y -= employee.speed
    end

    puts employee.y - all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y)

    if employee.y < all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y)
      employee.speed = 4
      employee.y += employee.speed
    end

    if employee.go_to_aco_number <= 3
      if employee.x >= all_aco[employee.go_to_aco_number].x * 36 && employee.y - all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y) > 0 && employee.y - all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y) <= 32
        employee.x -= employee.speed
        if employee.x <= all_aco[employee.go_to_aco_number].x * 36
          employee.at_aco = true
        end
      end

    else
      puts employee.y - all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y)
      if employee.x <= all_aco[employee.go_to_aco_number].x * 18 && employee.y - all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y) > 0 && employee.y - all_aco[employee.go_to_aco_number].y * 22 + (all_aco[employee.go_to_aco_number].y) <= 35
        employee.x += employee.speed
        if employee.x >= all_aco[employee.go_to_aco_number].x * 18
          employee.at_aco = true
        end
      end
    end
  end
end

def employee_fixing_aco (employee, all_aco)
  if employee.at_aco == true
    if (Gosu.milliseconds % 3000 >= 0) and (Gosu.milliseconds % 3000 <= 15)
      employee.at_aco = false
      employee.back_to_position = true
      all_aco[employee.go_to_aco_number].broken = false
    end
  end
end

def employee_move_to_default_position(employee, aco)
  if employee.at_aco == false and employee.go_to_aco_number != nil and employee.back_to_position == true
    if employee.x <= aco[employee.go_to_aco_number].x * 36 && employee.x >= 180
      employee.x -= employee.speed
    end

    if employee.x >= aco[employee.go_to_aco_number].x * 35 && employee.x <= 180
      employee.x += employee.speed
    end

    if employee.x >= 177 and employee.x <= 181
      employee.back_to_position = false
      employee.go_to_aco_number = nil
    end
  end
end

def which_employee_selected(employees)
  index = 0

  while index < employees.length
    if employees[index].is_selected == true
      return employees[index]
    end
    index += 1
  end

  return nil

end

def setup_timer
  @font_timer.draw("Timer: " + @seconds.to_s, 400, 55, 2, 1, 1, Gosu::Color::BLUE)
end

class GameWindow < Gosu::Window
  def initialize
    super(MAP_WIDTH, MAP_HEIGHT, false)
    self.caption = "Target Simulator"

    @all_aco = []

    @game_map = read_game_map("media/target_map.txt")

    @customers = []
    @customer = setup_customer(@customer, 500, 100)
    @customers << @customer

    @customers_in_aco = []

    @font = Gosu::Font.new(12)

    @font_score = Gosu::Font.new(36)
    @score = 0

    @employees = []
    @employee1 = setup_employee(@employee1, 170, 200)
    @employee2 = setup_employee(@employee2, 170, 390)
    @employees << @employee1
    @employees << @employee2


    @seconds = 0
    @last_time = Gosu::milliseconds()
    @font_timer = Gosu::Font.new(36)


  end

  def needs_cursor?
    true
  end

  def update
    @customers.each do |customer|
      if customer.x > 350
        move_customer_in_line(customer)
      end
    end

    @customers_in_aco.each do |customer|
      move_customer_to_aco(customer, @all_aco)
      move_customer_to_exit(customer, @all_aco)
    end

    if (rand < CUSTOMER_FREQUENCY) && line_free(@customers)
      customer = setup_customer(customer, 500, 100)
      @customers.push customer
    end
    check_customer_collision(@customers)

    if (rand < ACO_BREAKS)
      random_broken = rand(0..9)

      if @all_aco[random_broken].broken == false
        @all_aco[random_broken].broken = true
        puts "ACO number " + random_broken.to_s + " is broken"
      end
    end

    @employees.each do |employee|
      move_employee_to_aco(employee, @all_aco)
      employee_fixing_aco(employee, @all_aco)
      employee_move_to_default_position(employee, @all_aco)
    end

    if (Gosu::milliseconds - @last_time) / 1000 == 1
      @seconds += 1
      @last_time = Gosu::milliseconds
    end
  end

  def draw
    draw_game_map(@game_map)
    @customers.each do |customer|
      draw_customer(customer)
      if customer.is_selected == true
        highlight_customer(@customers, customer)
      end
    end

    @customers_in_aco.each do |customer|
      draw_customer(customer)
      if customer.is_selected == true
        highlight_customer(@customers_in_aco, customer)
      end
    end

    @all_aco.each do |aco|
      if aco.is_selected == true
        highlight_aco(@all_aco, aco)
      end
    end

    @employees.each do |employee|
      draw_employee(employee)
      if employee.is_selected == true
        highlight_employee(@employees, employee)
      end
    end

    draw_score
    all_aco_status(@all_aco)

    setup_timer
  end

  def button_down(id)
    case id
    when Gosu::MsLeft
      puts "mouse x: " + mouse_x.to_s
      puts "mouse y: " + mouse_y.to_s
      customer_picked = customer_clicked(@customers, mouse_x,  mouse_y, mouse_x, mouse_y)
      focus_on_customer(@customers, customer_picked)

      employee_picked = employee_clicked(@employees, mouse_x, mouse_y, mouse_x, mouse_y)
      focus_on_employee(@employees, employee_picked)

    when Gosu::MsRight
      aco_picked = aco_clicked(@all_aco, mouse_x,  mouse_y, mouse_x, mouse_y)
      focus_on_aco(@all_aco, aco_picked)

    when Gosu::KbSpace
      customer_selected_for_path = which_customer_selected(@customers)
      aco_selected_for_path = which_aco_selected(@all_aco)
      employee_selected_for_path = which_employee_selected(@employees)

      if @customers[0].x <= 375 and aco_selected_for_path != nil and customer_selected_for_path != nil and aco_selected_for_path.busy == false and aco_selected_for_path.broken == false
        @customers_in_aco << @customers[0]
        @customers.shift
      end
      if customer_selected_for_path && aco_selected_for_path
        path_picked_customer(customer_selected_for_path, aco_selected_for_path)
        customer_selected_for_path.is_selected = false
        aco_selected_for_path.is_selected = false
      end
      if employee_selected_for_path && aco_selected_for_path
        path_picked_employee(employee_selected_for_path, aco_selected_for_path)
        employee_selected_for_path.is_selected = false
        aco_selected_for_path.is_selected = false
      end

    when Gosu::KbA
      # index = 0
      # while index < @employees.length
      #   puts "Employee number " + index.to_s + ": " + @employees[index].is_selected.to_s
      #   index += 1
      # end

      puts "Employee 1 y: " + @employees[1].y.to_s
      puts "But needs to be at: " + @all_aco[@employees[1].go_to_aco_number].y * 22 + (@all_aco[@employees[1].go_to_aco_number].y)
      puts "Equation total: " + (@employees[1].y.to_s - @all_aco[@employees[1].go_to_aco_number].y * 22 + (@all_aco[@employees[1].go_to_aco_number].y)).to_s
      # puts "ACO 0 is: " + @all_aco[@employees[0].go_to_aco_number].x * 36
      # puts "Employee 1 x: " + @employees[1].x.to_s

      # puts "Employee X subtracted by the radius: " + (@employees[0].x + 15 - @employees[0].radius).to_s
      # puts "Employee x added with the radius: " + (@employees[0].x + 15 + @employees[0].radius).to_s


    when Gosu::KbEscape
      exit
    end
  end

end

window = GameWindow.new
window.show
