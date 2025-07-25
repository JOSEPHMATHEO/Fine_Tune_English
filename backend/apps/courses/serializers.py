from rest_framework import serializers
from .models import Course, CourseGroup, Enrollment, Schedule, Grade, Classroom, Period

class CourseSerializer(serializers.ModelSerializer):
    class Meta:
        model = Course
        fields = '__all__'

class ClassroomSerializer(serializers.ModelSerializer):
    class Meta:
        model = Classroom
        fields = '__all__'

class PeriodSerializer(serializers.ModelSerializer):
    class Meta:
        model = Period
        fields = '__all__'

class ScheduleSerializer(serializers.ModelSerializer):
    classroom = ClassroomSerializer(read_only=True)
    day_name = serializers.CharField(source='get_day_of_week_display', read_only=True)

    class Meta:
        model = Schedule
        fields = ['id', 'day_of_week', 'day_name', 'start_time', 'end_time', 'classroom', 'subject']

class TeacherProfileSerializer(serializers.ModelSerializer):
    user = serializers.SerializerMethodField()

    class Meta:
        model = 'users.TeacherProfile'
        fields = ['user', 'especialization', 'hire_date']

    def get_user(self, obj):
        return {
            'id': obj.user.id,
            'nombre_completo': obj.user.nombre_completo,
            'correo': obj.user.correo,
            'rol': obj.user.rol
        }

class CourseGroupSerializer(serializers.ModelSerializer):
    course = CourseSerializer(read_only=True)
    teacher = serializers.SerializerMethodField()
    period = PeriodSerializer(read_only=True)
    schedules = ScheduleSerializer(many=True, read_only=True)

    class Meta:
        model = CourseGroup
        fields = ['id', 'course', 'teacher', 'period', 'name', 'max_students', 'schedules']

    def get_teacher(self, obj):
        if obj.teacher:
            return {
                'user': {
                    'id': obj.teacher.user.id,
                    'nombre_completo': obj.teacher.user.nombre_completo,
                    'correo': obj.teacher.user.correo,
                    'rol': obj.teacher.user.rol
                },
                'especialization': obj.teacher.especialization,
                'hire_date': obj.teacher.hire_date
            }
        return None

class EnrollmentSerializer(serializers.ModelSerializer):
    course_group = CourseGroupSerializer(read_only=True)

    class Meta:
        model = Enrollment
        fields = ['id', 'course_group', 'enrollment_date', 'is_active']

class GradeSerializer(serializers.ModelSerializer):
    percentage = serializers.ReadOnlyField()
    grade_type_display = serializers.CharField(source='get_grade_type_display', read_only=True)

    class Meta:
        model = Grade
        fields = ['id', 'grade_type', 'grade_type_display', 'subject', 'obtained_score', 'max_score', 'percentage', 'date', 'comments']