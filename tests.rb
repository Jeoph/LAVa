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
    a = School.create(name: "Appalachian State University")
    s = Term.create(name: "Spring 2016")
    f = Term.create(name: "Fall 2016")
    a.terms = [s, f]
    assert_equal a.terms, [s, f]
  end

  def test_associate_terms_with_courses
    output = ""
    s = Term.create(name: "Spring 2016")
    a = Course.create(name: "Accounting")
    c = Course.create(name: "Communication")
    s.courses = [a, c]
    assert_raises do s.destroy end
    f = Term.create(name: "Fall 2016")
    f.destroy
    assert f.destroyed?
  end

  def test_associate_courses_with_course_students
    output = ""
    a = Course.create(name: "Accounting")
    g = CourseStudent.create(student_id: 1)
    j = CourseStudent.create(student_id: 2)
    a.course_students = [g, j]
    assert_raises do a.destroy end
    c = Course.create(name: "Communication")
    c.destroy
    assert c.destroyed?
  end

  def test_associate_assignments_with_courses
    c = Course.create(name: "Computer Programming")
    a = Assignment.create(name: "Test Driven Development")
    c.assignments << a
    c.destroy
    assert c.destroyed?
    assert a.destroyed?
  end

  def test_associate_lessons_with_pre_class_assignments
    skip
  end

  def test_school_has_many_courses_through_terms
    a = School.create(name: "Appalachian State University")
    s = Term.create(name: "Spring 2016")
    c = Course.create(name: "Communication")
    a.terms << s
    s.courses << c
    a.save!
    s.save!
    c.save!
    assert a.courses.include?(c)
  end

  def test_validate_that_lessons_have_names
    l = Lesson.create()
    refute l.valid?
  end

  def test_validate_that_readings_have_order_number_lesson_id_and_url
    r = Reading.create()
    refute r.valid?
  end

  def test_validate_reading_url_must_start_with_http_or_https
    assert_raises do Reading.create!(order_number: 1, lesson_id: 1, url: "junk://") end
    reading = Reading.create!(order_number: 2, lesson_id: 2, url: "http://www.booyah.com")
    assert reading.valid?
    another_reading = Reading.create!(order_number: 3, lesson_id: 3, url: "https://jeoph.com")
    assert another_reading.valid?
  end
end
