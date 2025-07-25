from rest_framework import serializers
from .models import Task, TaskSubmission

class TaskSerializer(serializers.ModelSerializer):
    course_group_data = serializers.SerializerMethodField()

    class Meta:
        model = Task
        fields = [
            'id', 'title', 'description', 'task_type',
            'course_group', 'course_group_data', 'due_date', 'priority',
            'max_score', 'instructions', 'attachments', 'is_active', 'created_at'
        ]
        extra_kwargs = {
            'course_group': {'write_only': True}
        }

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['task_type_display'] = instance.get_task_type_display()
        data['priority_display'] = instance.get_priority_display()
        return data

    def get_course_group_data(self, obj):
        if obj.course_group:
            return {
                'id': obj.course_group.id,
                'name': obj.course_group.name,
                'course': {
                    'id': obj.course_group.course.id,
                    'name': obj.course_group.course.name,
                    'code': obj.course_group.course.code,
                    'level': obj.course_group.course.level
                },
                'teacher': {
                    'user': {
                        'nombre_completo': obj.course_group.teacher.user.nombre_completo
                    }
                } if obj.course_group.teacher else None
            }
        return None

class TaskSubmissionSerializer(serializers.ModelSerializer):
    task = TaskSerializer(read_only=True)

    class Meta:
        model = TaskSubmission
        fields = [
            'id', 'task', 'submission_text', 'attachment', 'submitted_at',
            'status', 'score', 'feedback', 'graded_at'
        ]

    def to_representation(self, instance):
        data = super().to_representation(instance)
        data['status_display'] = instance.get_status_display()
        return data