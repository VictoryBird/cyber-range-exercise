"""
시드 데이터 생성 커맨드.
7개 부서, 10명 직원, 5개 공지사항, 5개 결재, 4개 업무요청을 생성한다.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from accounts.models import Department, UserProfile
from notices.models import Notice
from approvals.models import Approval, ApprovalLine
from work_requests.models import WorkRequest
from datetime import date, timedelta
from django.utils import timezone


class Command(BaseCommand):
    help = '훈련용 초기 시드 데이터를 생성합니다.'

    def handle(self, *args, **options):
        self.stdout.write('시드 데이터 생성 시작...')

        # ===== 1. 부서 생성 (7개) =====
        departments_data = [
            {'name': '정책실', 'code': 'POL'},
            {'name': '사이버작전사령부', 'code': 'CYBER'},
            {'name': '인사혁신과', 'code': 'HR'},
            {'name': 'IT운영팀', 'code': 'ITOPS'},
            {'name': '정보보안정책과', 'code': 'SEC'},
            {'name': '전자정부과', 'code': 'EGOV'},
            {'name': '총무과', 'code': 'GA'},
        ]
        departments = {}
        for dept_data in departments_data:
            dept, created = Department.objects.get_or_create(
                code=dept_data['code'],
                defaults={'name': dept_data['name']}
            )
            departments[dept_data['name']] = dept
            if created:
                self.stdout.write(f'  부서 생성: {dept.name}')

        # ===== 2. 직원 생성 (10명) =====
        employees_data = [
            {
                'username': 'admin_park', 'password': '@dminP@rk2026!',
                'first_name': '박관리', 'email': 'admin_park@corp.mois.local',
                'department': '정보보안정책과', 'position': '서기관',
                'phone': '02-2100-0001', 'employee_number': 'MOIS-2020-0001',
                'joined_at': date(2020, 1, 2), 'is_staff': True, 'is_superuser': True,
            },
            {
                'username': 'kimbs', 'password': 'KimB$2026',
                'first_name': '김보안', 'email': 'kimbs@corp.mois.local',
                'department': '정보보안정책과', 'position': '과장',
                'phone': '02-2100-0010', 'employee_number': 'MOIS-2021-0015',
                'joined_at': date(2021, 6, 15), 'is_staff': True, 'is_superuser': False,
            },
            {
                'username': 'leecs', 'password': 'Lee(S2026',
                'first_name': '이철수', 'email': 'leecs@corp.mois.local',
                'department': '정책실', 'position': '주무관',
                'phone': '02-2100-1234', 'employee_number': 'MOIS-2024-0052',
                'joined_at': date(2024, 3, 1), 'is_staff': False, 'is_superuser': False,
            },
            {
                'username': 'jungmj', 'password': 'Jung!MJ26',
                'first_name': '정민지', 'email': 'jungmj@corp.mois.local',
                'department': '총무과', 'position': '주무관',
                'phone': '02-2100-2001', 'employee_number': 'MOIS-2023-0041',
                'joined_at': date(2023, 2, 1), 'is_staff': False, 'is_superuser': False,
            },
            {
                'username': 'choiyh', 'password': '(hoiYH26!',
                'first_name': '최영호', 'email': 'choiyh@corp.mois.local',
                'department': '전자정부과', 'position': '사무관',
                'phone': '02-2100-3001', 'employee_number': 'MOIS-2022-0028',
                'joined_at': date(2022, 7, 1), 'is_staff': True, 'is_superuser': False,
            },
            {
                'username': 'hwangse', 'password': 'Hwang$E26',
                'first_name': '황서은', 'email': 'hwangse@corp.mois.local',
                'department': '사이버작전사령부', 'position': '주무관',
                'phone': '02-2100-4001', 'employee_number': 'MOIS-2024-0060',
                'joined_at': date(2024, 6, 1), 'is_staff': False, 'is_superuser': False,
            },
            {
                'username': 'seojs', 'password': 'SeoJ$2026',
                'first_name': '서정수', 'email': 'seojs@corp.mois.local',
                'department': '정보보안정책과', 'position': '주무관',
                'phone': '02-2100-0012', 'employee_number': 'MOIS-2023-0035',
                'joined_at': date(2023, 4, 1), 'is_staff': False, 'is_superuser': False,
            },
            {
                'username': 'kangdh', 'password': 'Kang!DH26',
                'first_name': '강동훈', 'email': 'kangdh@corp.mois.local',
                'department': '정책실', 'position': '팀장',
                'phone': '02-2100-1200', 'employee_number': 'MOIS-2019-0008',
                'joined_at': date(2019, 3, 1), 'is_staff': True, 'is_superuser': False,
            },
            {
                'username': 'ohms', 'password': 'Oh!M$2026',
                'first_name': '오민수', 'email': 'ohms@corp.mois.local',
                'department': '총무과', 'position': '과장',
                'phone': '02-2100-2000', 'employee_number': 'MOIS-2020-0005',
                'joined_at': date(2020, 2, 1), 'is_staff': True, 'is_superuser': False,
            },
            {
                'username': 'yoonhj', 'password': 'Yoon#HJ26',
                'first_name': '윤혜진', 'email': 'yoonhj@corp.mois.local',
                'department': '전자정부과', 'position': '주무관',
                'phone': '02-2100-3010', 'employee_number': 'MOIS-2025-0070',
                'joined_at': date(2025, 1, 2), 'is_staff': False, 'is_superuser': False,
            },
        ]

        users = {}
        for emp in employees_data:
            user, created = User.objects.get_or_create(
                username=emp['username'],
                defaults={
                    'first_name': emp['first_name'],
                    'email': emp['email'],
                    'is_staff': emp['is_staff'],
                    'is_superuser': emp['is_superuser'],
                }
            )
            if created:
                user.set_password(emp['password'])
                user.save()
                self.stdout.write(f'  사용자 생성: {emp["username"]} ({emp["first_name"]})')

            dept_ref = departments.get(emp['department'])
            profile, _ = UserProfile.objects.get_or_create(
                user=user,
                defaults={
                    'department': emp['department'],
                    'department_ref': dept_ref,
                    'position': emp['position'],
                    'phone': emp['phone'],
                    'employee_number': emp['employee_number'],
                    'joined_at': emp['joined_at'],
                    'ad_username': emp['username'],
                }
            )
            users[emp['username']] = user

        # ===== 3. 공지사항 생성 (5개) =====
        notices_data = [
            {
                'title': '2026년 상반기 보안 교육 일정 안내',
                'content': '전 직원 대상 보안 교육을 아래와 같이 실시합니다.\n\n1. 일시: 2026년 4월 15일 (화) 14:00~16:00\n2. 장소: 대회의실 (3층)\n3. 대상: 전 직원 (필참)\n4. 내용: 사이버 보안 위협 동향 및 대응 방안\n\n교육 미참석 시 별도 보충 교육을 이수해야 합니다.',
                'category': '보안', 'department': '정보보안정책과',
                'author': 'kimbs', 'is_pinned': True,
            },
            {
                'title': '인트라넷 시스템 정기 점검 안내 (4/5)',
                'content': '인트라넷 시스템 정기 점검을 다음과 같이 실시합니다.\n\n- 일시: 2026년 4월 5일 (토) 22:00 ~ 4월 6일 (일) 06:00\n- 대상: 내부 업무 포털, 전자결재 시스템\n- 영향: 점검 시간 중 서비스 이용 불가\n\n업무에 참고하시기 바랍니다.',
                'category': 'IT', 'department': 'IT운영팀',
                'author': 'choiyh', 'is_pinned': True,
            },
            {
                'title': '2026년 상반기 인사이동 안내',
                'content': '2026년 상반기 인사이동 결과를 아래와 같이 안내드립니다.\n\n[전보]\n- 이철수 주무관: 기획조정과 → 정책실\n- 황서은 주무관: 재난안전과 → 사이버작전사령부\n\n발령일: 2026년 3월 1일',
                'category': '인사', 'department': '인사혁신과',
                'author': 'admin_park', 'is_pinned': False,
            },
            {
                'title': '청사 내 주차장 이용 안내사항 변경',
                'content': '2026년 4월부터 청사 내 주차장 이용 규정이 변경됩니다.\n\n1. 주차 등록제 시행 (차량번호 사전 등록 필수)\n2. 외부 방문자 주차는 B2층으로 변경\n3. 전기차 충전 구역 확대 (B1층 10대분)\n\n차량 등록은 총무과로 문의 바랍니다.',
                'category': '일반', 'department': '총무과',
                'author': 'jungmj', 'is_pinned': False,
            },
            {
                'title': '전자정부 서비스 품질 개선 워크숍 참석 안내',
                'content': '전자정부과에서 주관하는 서비스 품질 개선 워크숍에 참석 바랍니다.\n\n- 일시: 2026년 4월 20일 (월) 10:00~12:00\n- 장소: 소회의실 B (2층)\n- 대상: 전자정부과, IT운영팀 직원\n- 안건: 행정 서비스 사용자 경험 개선 방안',
                'category': '행사', 'department': '전자정부과',
                'author': 'choiyh', 'is_pinned': False,
            },
        ]

        for notice_data in notices_data:
            author = users.get(notice_data.pop('author'))
            notice, created = Notice.objects.get_or_create(
                title=notice_data['title'],
                defaults={**notice_data, 'author': author}
            )
            if created:
                self.stdout.write(f'  공지사항 생성: {notice.title[:30]}...')

        # ===== 4. 전자결재 생성 (5개) =====
        approvals_data = [
            {
                'title': '2026년 3월 출장비 정산 요청',
                'type': 'expense', 'status': 'pending',
                'requester': 'leecs', 'content': '출장 내역: 세종시 행안부 본부 방문\n출장일: 2026-03-20 ~ 2026-03-21\n교통비: 80,000원\n숙박비: 70,000원\n합계: 150,000원',
                'amount': 150000,
                'approvers': [('kangdh', 'pending'), ('ohms', 'waiting')],
            },
            {
                'title': '연차휴가 신청 (4/10~4/11)',
                'type': 'leave', 'status': 'approved',
                'requester': 'jungmj', 'content': '개인 사유로 연차 휴가를 신청합니다.\n기간: 2026-04-10 ~ 2026-04-11 (2일)',
                'amount': None,
                'approvers': [('ohms', 'approved')],
            },
            {
                'title': '보안장비 도입 품의서',
                'type': 'purchase', 'status': 'pending',
                'requester': 'kimbs', 'content': '차세대 방화벽 도입을 위한 품의서입니다.\n\n1. 품명: FortiGate 600F\n2. 수량: 2대\n3. 금액: 45,000,000원\n4. 납기: 계약 후 30일',
                'amount': 45000000,
                'approvers': [('admin_park', 'pending')],
            },
            {
                'title': '전산실 에어컨 교체 요청',
                'type': 'general', 'status': 'approved',
                'requester': 'choiyh', 'content': '전산실 항온항습기 노후화로 교체를 요청합니다.\n현재 장비: 2018년 설치, 고장 빈발\n교체 사유: 서버실 온도 관리 불량',
                'amount': 8000000,
                'approvers': [('kangdh', 'approved'), ('admin_park', 'approved')],
            },
            {
                'title': '4월 보안 점검 계획(안)',
                'type': 'general', 'status': 'pending',
                'requester': 'seojs', 'content': '2026년 4월 정기 보안 점검 계획을 보고합니다.\n\n1. 점검 대상: 전 부서 PC 및 서버\n2. 점검 기간: 2026-04-07 ~ 2026-04-18\n3. 점검 항목: 백신 업데이트, 패스워드 정책 준수, 비인가 소프트웨어',
                'amount': None,
                'approvers': [('kimbs', 'pending'), ('admin_park', 'waiting')],
            },
        ]

        for appr_data in approvals_data:
            requester = users.get(appr_data['requester'])
            approvers_list = appr_data.pop('approvers')
            approval, created = Approval.objects.get_or_create(
                title=appr_data['title'],
                defaults={
                    'type': appr_data['type'],
                    'status': appr_data['status'],
                    'requester': requester,
                    'content': appr_data['content'],
                    'amount': appr_data['amount'],
                }
            )
            if created:
                for order, (approver_name, line_status) in enumerate(approvers_list, 1):
                    approver = users.get(approver_name)
                    ApprovalLine.objects.create(
                        approval=approval,
                        approver=approver,
                        order=order,
                        status=line_status,
                        acted_at=timezone.now() if line_status == 'approved' else None,
                    )
                self.stdout.write(f'  결재 생성: {approval.title[:30]}...')

        # ===== 5. 업무요청 생성 (4개) =====
        work_requests_data = [
            {
                'title': 'VPN 접속 계정 발급 요청',
                'content': '재택근무용 VPN 접속 계정 발급을 요청합니다.\n\n대상자: 이철수 주무관\n사유: 재택근무 지원\n기간: 2026-04-01 ~ 2026-06-30',
                'requester': 'leecs', 'assignee': 'seojs',
                'from_department': '정책실', 'to_department': '정보보안정책과',
                'priority': 'medium', 'status': 'open',
                'due_date': date(2026, 3, 31),
            },
            {
                'title': '회의실 프로젝터 수리 요청',
                'content': '3층 대회의실 프로젝터가 작동하지 않습니다.\n증상: 전원은 켜지나 화면 출력 안됨\n확인일: 2026-03-25',
                'requester': 'jungmj', 'assignee': 'choiyh',
                'from_department': '총무과', 'to_department': '전자정부과',
                'priority': 'high', 'status': 'in_progress',
                'due_date': date(2026, 3, 28),
            },
            {
                'title': '신규 직원 PC 세팅 요청',
                'content': '4월 입사 예정 신규 직원의 업무용 PC 세팅을 요청합니다.\n\n인원: 2명\n부서: 사이버작전사령부, 전자정부과\n필요 소프트웨어: MS Office, 한글, 내부 업무 포털 접근 설정',
                'requester': 'ohms', 'assignee': 'choiyh',
                'from_department': '총무과', 'to_department': '전자정부과',
                'priority': 'medium', 'status': 'open',
                'due_date': date(2026, 4, 1),
            },
            {
                'title': '보안 사고 대응 훈련 협조 요청',
                'content': '2026년 상반기 사이버 보안 사고 대응 훈련을 위해 각 부서의 협조를 요청합니다.\n\n훈련 일시: 2026-04-22 14:00~17:00\n참여 부서: 전 부서\n필요 사항: 부서별 보안 담당자 1명 지정',
                'requester': 'kimbs', 'assignee': 'hwangse',
                'from_department': '정보보안정책과', 'to_department': '사이버작전사령부',
                'priority': 'urgent', 'status': 'open',
                'due_date': date(2026, 4, 15),
            },
        ]

        for wr_data in work_requests_data:
            requester = users.get(wr_data.pop('requester'))
            assignee = users.get(wr_data.pop('assignee'))
            wr, created = WorkRequest.objects.get_or_create(
                title=wr_data['title'],
                defaults={
                    **wr_data,
                    'requester': requester,
                    'assignee': assignee,
                }
            )
            if created:
                self.stdout.write(f'  업무요청 생성: {wr.title[:30]}...')

        self.stdout.write(self.style.SUCCESS('시드 데이터 생성 완료!'))
        self.stdout.write(f'  부서: {Department.objects.count()}개')
        self.stdout.write(f'  사용자: {User.objects.count()}명')
        self.stdout.write(f'  공지사항: {Notice.objects.count()}개')
        self.stdout.write(f'  결재: {Approval.objects.count()}개')
        self.stdout.write(f'  업무요청: {WorkRequest.objects.count()}개')
