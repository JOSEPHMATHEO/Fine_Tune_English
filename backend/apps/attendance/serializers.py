from rest_framework import serializers
from .models import Attendance, AttendanceSession, AttendanceSummary
from apps.courses.models import CourseGroup

class AttendanceSessionSerializer(serializers.ModelSerializer):
    course_group_id = serializers.PrimaryKeyRelatedField(
        source='course_group',
        queryset=CourseGroup.objects.all(),
        write_only=True
    )
    course_group = serializers.SerializerMethodField(read_only=True)
    schedule = serializers.SerializerMethodField()

    class Meta:
        model = AttendanceSession
        fields = '__all__'

    def get_course_group(self, obj):
        if obj.course_group:
            return {
                'id': obj.course_group.id,
                'name': obj.course_group.name,
                'course': {
                    'name': obj.course_group.course.name,
                    'code': obj.course_group.course.code
                }
            }
        return None

    def get_schedule(self, obj):
        if obj.schedule:
            return {
                'id': obj.schedule.id,
                'day_of_week': obj.schedule.day_of_week,
                'day_name': obj.schedule.get_day_of_week_display(),
                'start_time': obj.schedule.start_time,
                'end_time': obj.schedule.end_time,
                'subject': obj.schedule.subject
            }
        return None

class AttendanceSerializer(serializers.ModelSerializer):
    session = AttendanceSessionSerializer(read_only=True)
    student = serializers.SerializerMethodField()

    class Meta:
        model = Attendance
        fields = [
            'id', 'session', 'student', 'status',
            'arrival_time', 'notes', 'marked_at'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['status_display'] = instance.get_status_display()
        return data

    def get_student(self, obj):
        if obj.student:
            return {
                'user': {
                    'id': obj.student.user.id,
                    'nombre_completo': obj.student.user.nombre_completo,
                    'correo': obj.student.user.correo
                }
            }
        return None

class AttendanceSummarySerializer(serializers.ModelSerializer):
    student = serializers.SerializerMethodField()
    course_group = serializers.SerializerMethodField()

    class Meta:
        model = AttendanceSummary
        fields = '__all__'

    def get_student(self, obj):
        if obj.student:
            return {
                'user': {
                    'id': obj.student.user.id,
                    'nombre_completo': obj.student.user.nombre_completo,
                    'correo': obj.student.user.correo
                }
            }
        return None

    def get_course_group(self, obj):
        if obj.course_group:
            return {
                'id': obj.course_group.id,
                'name': obj.course_group.name,
                'course': {
                    'name': obj.course_group.course.name,
                    'code': obj.course_group.course.code
                }
            }
        return None