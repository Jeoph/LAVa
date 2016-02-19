# Basic test requires
require 'minitest/autorun'
require 'minitest/pride'

# Include both the migration and the app itself
require './migration'
require './application'

# Overwrite the development database connection with a test connection.
ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: 'test.sqlite3'
)

ActiveRecord::Migration.verbose = false

# Gotta run migrations before we can run tests.  Down will fail the first time,
# so we wrap it in a begin/rescue.
begin ApplicationMigration.migrate(:down); rescue; end
ApplicationMigration.migrate(:up)


# Finally!  Let's test the thing.
class ApplicationTest < Minitest::Test

  def test_truth
    assert true
  end


  def test_associate_schools_with_terms
    a = School.create!(name: "Appalachian State University")
    s = Term.create!(name: "Spring 2016", starts_on: 2016/1/1, ends_on: 2016/6/1, school_id: a.id)
    f = Term.create!(name: "Fall 2016", starts_on: 2016/8/1, ends_on: 2016/12/1, school_id: a.id)
    a.terms = [s, f]
    assert_equal a.terms, [s, f]
  end

  def test_associate_terms_with_courses
    a = School.create!(name: "Appalachian State University")
    s = Term.create!(name: "Spring 2015", starts_on: 2016/1/1, ends_on: 2016/6/1, school_id: a.id)
    a = Course.create!(name: "Psychology", course_code: "PSY101")
    c = Course.create!(name: "Algebra", course_code: "MAT101")
    s.courses = [a, c]
    assert_raises do s.destroy end
    f = Term.create!(name: "Fall 2016", starts_on: 2016/8/1, ends_on: 2016/12/1, school_id: a.id)
    f.destroy
    assert f.destroyed?
  end

  def test_associate_courses_with_course_students
    output = ""
    a = Course.create!(name: "Tennis", course_code: "PHY101")
    g = CourseStudent.create!(student_id: 1)
    j = CourseStudent.create!(student_id: 2)
    a.course_students = [g, j]
    assert_raises do a.destroy end
    c = Course.create!(name: "Calculus", course_code: "MAT201")
    c.destroy
    assert c.destroyed?
  end

  def test_associate_assignments_with_courses
    c = Course.create!(name: "Computer Programming", course_code: "CSP101")
    a = Assignment.create!(course_id: c.id, name: "Test Driven Development", percent_of_grade: 0.2)
    c.assignments << a
    c.destroy
    assert c.destroyed?
    assert a.destroyed?
  end

  def test_associate_lessons_with_pre_class_assignments
    c = Course.create!(name: "Computer Programming", course_code: "CSP102")
    a = Assignment.create!(course_id: c.id, name: "Something clever", percent_of_grade: 0.2)
    l = Lesson.create!(name: "Figure out how to make it work!")
    a.pre_class_assignments << l
    assert_equal a.pre_class_assignments.first, l
  end

  def test_school_has_many_courses_through_terms
    a = School.create!(name: "Appalachian State University")
    s = Term.create!(name: "Spring 2016", starts_on: 2016/1/1, ends_on: 2016/6/1, school_id: a.id)
    c = Course.create!(name: "Biology", course_code: "BIO101")
    a.terms << s
    s.courses << c
    a.save!
    s.save!
    c.save!
    assert a.courses.include?(c)
  end

  def test_validate_that_lessons_have_names
    assert_raises do l = Lesson.create!() end
  end

  def test_validate_that_readings_have_order_number_lesson_id_and_url
    assert_raises do r = Reading.create!() end
  end

  def test_validate_reading_url_must_start_with_http_or_https
    assert_raises do Reading.create!(order_number: 1, lesson_id: 1, url: "junk://") end
    reading = Reading.create!(order_number: 2, lesson_id: 2, url: "http://www.booyah.com")
    assert reading.valid?
    another_reading = Reading.create!(order_number: 3, lesson_id: 3, url: "https://jeoph.com")
    assert another_reading.valid?
  end

  def test_courses_must_have_course_code_and_name
    assert_raises do Course.create!(name: "Communication") end
    assert_raises do Course.create!(course_code: "COM101") end
    c = Course.create(name: "Communication", course_code: "COM101")
    assert c.valid?
  end

  def test_courses_must_have_unique_course_code_within_term_id
    a = School.create!(name: "Appalachian State University")
    s = Term.create!(name: "Spring 2016", starts_on: 2016/1/1, ends_on: 2016/6/1, school_id: a.id)
    f = Term.create!(name: "Fall 2016", starts_on: 2016/8/1, ends_on: 2016/12/1, school_id: a.id)
    a = Course.new(name: "Accounting", course_code: "ACC101")
    c = Course.new(name: "Communication", course_code: "ACC101")
    s.courses << a
    s.courses << c
    assert_raises do s.save! end
    f.courses << c
    assert f.save!
  end

  def test_validate_course_code_starts_with_three_letters_and_ends_with_three_numbers
    a = Course.new(name: "Accounting", course_code: "123ACC")
    assert_raises do a.save! end
  end

#   def test_associate_lessons_with_readings_and_destroy_readings_with_lessons
#     l = Lesson.create(name: "Defense Against Ruby Black Magic")
#     r1 = Reading.create(caption: "Do You Believe In Magic?", url: "http://gilesbowkett.blogspot.com/2009/07/do-you-believe-in-magic.html")
#     r2 = Reading.create(caption: "Why Ruby on Rails won't become mainstream", url: "http://beust.com/weblog/2006/04/06/why-ruby-on-rails-wont-become-mainstream/")
#     l.readings << r1
#     l.readings << r2
#     assert_equal [r1, r2], l.readings
#     l.destroy
#     assert l.destroyed?
#     assert r1.destroyed?
#     # assert l.where(id: r1.id).empty?
#   end
#
#   def test_associate_lessons_with_courses_and_destroy_lessons_with_courses
#     c = Course.create(name: "A Ruby Is Not A Gem")
#     l1 = Lesson.create(name: "Defense Against Ruby Black Magic")
#     l2 = Lesson.create(name: "The History of Introverts Creating New Ways To Avoid Direct Contact: Computing Languages")
#     c.lessons << l1
#     c.lessons << l2
#     assert_equal [l1, l2], c.lessons
#     c.destroy
#     assert c.destroyed?
#     assert l1.destroyed?
#     # assert Course.where(id: l1.id).empty?
#   end
#
#   def test_associate_courses_with_course_instructors_but_not_destroy_with_course_instructors
#     course = Course.create(name: "A Ruby Is Not A Gem")
#     i = CourseInstructor.create()
#     course.course_instructors << i
#     assert_equal [i], course.course_instructors
#     assert_raises do course.destroy end
#   end
#
#   # def test_associate_lessons_with_in_class_assignments
#   #   l = Lesson.create(name: "Defense Against Ruby Black Magic")
#   #   a = Assignment.create(name: "WTF Ruby?")
#   #   l.assignments << a
#   #   assert Lesson.in_class_assignments.find(a.in_class_assignment_id)
#   # end
#
#   def test_course_has_many_readings
#     c = Course.create(name: "A Ruby Is Not A Gem")
#     l = Lesson.create(name: "Defense Against Ruby Black Magic")
#     c.lessons << l
#     r1 = Reading.create(caption: "Do You Believe In Magic?", url: "http://gilesbowkett.blogspot.com/2009/07/do-you-believe-in-magic.html")
#     r2 = Reading.create(caption: "Why Ruby on Rails won't become mainstream", url: "http://beust.com/weblog/2006/04/06/why-ruby-on-rails-wont-become-mainstream/")
#     l.readings << r1
#     l.readings << r2
#     assert_equal [r1, r2], c.readings
#   end
#
#   def test_school_must_have_name
#     s1 = School.create(name: "Introverts Unite")
#     s2 = School.create()
#     assert School.find(s1.id)
#     refute School.exists?(s2.id)
#   end
#
#   def test_terms_must_have_attributes
#     s = School.create(name: "Introverts Unite")
#     fall = Term.create(name: "Fall")
#     spring = Term.create(name: "Spring", starts_on: 2016/2/1, ends_on: 2016/4/22, school_id: s.id)
#     assert Term.find(spring.id)
#     refute Term.exists?(fall.id)
#   end
#
#   def test_user_must_have_attributes
#     u1 = User.create(first_name: "George Michael", last_name: "Bluth")
#     u2 = User.create(first_name: "Michael", last_name: "Bluth", email: "gobsuxors@gmail.com")
#     # refute_equal u2.first_name, nil
#     # refute_equal u2.last_name, nil
#     # refute_equal u2.email, nil
#     assert User.find(u2.id)
#     refute User.exists?(u1.id)
#   end
#
#   def test_user_email_unique_required
#     u1 = User.create(first_name: "Tobias", last_name: "Funke", email: "2blu4u@gmail.com")
#     u2 = User.create(first_name: "George Michael", last_name: "Bluth", email: "2blu4u@gmail.com")
#     # refute_equal u1.first_name, nil
#     # refute_equal u1.last_name, nil
#     # refute_equal u1.email, nil
#     assert User.find(u1.id)
#     refute User.exists?(u2.id)
#   end
#
#   def test_user_email_format_appropriate
#     u1 = User.create(first_name: "Tobias", last_name: "Funke", email: "actorz4ever@gmail.com")
#     u2 = User.create(first_name: "George Michael", last_name: "Bluth", email: "Y@LO@gmail.com")
#     assert User.find(u1.id)
#     refute User.exists?(u2.id)
#   end
#
#   def test_user_photo_url_start_correctly
#     u1 = User.create(first_name: "Tobias", last_name: "Funke", email: "never.nude@gmail.com", photo_url: "https://s-media-cache-ak0.pinimg.com/564x/28/54/40/285440d2714800f99169e8b3ac49969e.jpg")
#     u2 = User.create(first_name: "George Michael", last_name: "Bluth", email: "cuzinsluveachother@gmail.com", photo_url: "www.bananagrandstanding.jpg")
#     assert User.find(u1.id).inspect
#     refute User.exists?(u2.id)
#   end
#
#   def test_assignments_have_attributes
#     c = Course.create(name: "A Ruby Is Not A Gem")
#     a1 = Assignment.create(name: "What Ruby?")
#     a2 = Assignment.create(course_id: c.id, name: "WTF Ruby?", percent_of_grade: 0.2)
#     assert Assignment.find(a2.id)
#     refute Assignment.exists?(a1.id)
#   end
#
#   def test_assignments_are_unique_within_id
#     c = Course.create(name: "A Ruby Is Not A Gem")
#     a1 = Assignment.create(course_id: c.id, name: "WTF Ruby?", percent_of_grade: 0.4)
#     a2 = Assignment.create(course_id: c.id, name: "WTF Ruby?", percent_of_grade: 0.2)
#     assert Assignment.find(a1.id)
#     refute Assignment.exists?(a2.id)
#   end
end


# Person B:

# * Associate `lessons` with their `in_class_assignments` (both directions).
# * Validate that the Assignment `name` is unique within a given `course_id`.
#
# Don't forget to write tests for each of these before coding them!
#
