import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../data/models/job_application.dart';
import '../../cubits/jobs_cubit.dart';
import '../job_details/job_details_screen.dart';

/// Screen showing Interview Calendar and Follow-up Queue in tabs
class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({super.key});

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Interviews'),
            Tab(icon: Icon(Icons.notifications_active), text: 'Follow-ups'),
          ],
        ),
      ),
      body: BlocBuilder<JobsCubit, JobsState>(
        builder: (context, state) {
          final jobs = state.jobs;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildInterviewsTab(jobs, theme),
              _buildFollowUpsTab(jobs, theme),
            ],
          );
        },
      ),
    );
  }

  // ============================================
  // INTERVIEWS TAB
  // ============================================
  Widget _buildInterviewsTab(List<JobApplication> jobs, ThemeData theme) {
    // Filter jobs with interview dates
    final interviewJobs = jobs
        .where((j) => j.interviewDate != null && j.interviewDate!.isNotEmpty)
        .toList();

    // Build map of dates to jobs
    final interviewsByDate = <DateTime, List<JobApplication>>{};
    for (final job in interviewJobs) {
      try {
        final date = DateTime.parse(job.interviewDate!);
        final dateOnly = DateTime(date.year, date.month, date.day);
        interviewsByDate.putIfAbsent(dateOnly, () => []).add(job);
      } catch (_) {}
    }

    // Get interviews for selected date
    final selectedDateJobs = _selectedDate != null
        ? interviewsByDate[DateTime(
                _selectedDate!.year,
                _selectedDate!.month,
                _selectedDate!.day,
              )] ??
              []
        : <JobApplication>[];

    return Column(
      children: [
        // Custom Calendar
        _buildCalendar(interviewsByDate, theme),
        const Divider(height: 1),
        // Interview list for selected date
        Expanded(
          child: _selectedDate == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 48, color: theme.hintColor),
                      const SizedBox(height: 8),
                      Text(
                        'Tap a date to see interviews',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    ],
                  ),
                )
              : selectedDateJobs.isEmpty
              ? Center(
                  child: Text(
                    'No interviews on ${DateFormat('MMM d, yyyy').format(_selectedDate!)}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedDateJobs.length,
                  itemBuilder: (context, index) {
                    final job = selectedDateJobs[index];
                    return _buildInterviewCard(job, theme);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCalendar(
    Map<DateTime, List<JobApplication>> interviewsByDate,
    ThemeData theme,
  ) {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayOfMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(
                      _focusedMonth.year,
                      _focusedMonth.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Weekday headers
          Row(
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.hintColor,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final dayOffset = index - startingWeekday;
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox();
              }
              final day = dayOffset + 1;
              final date = DateTime(
                _focusedMonth.year,
                _focusedMonth.month,
                day,
              );
              final hasInterview = interviewsByDate.containsKey(date);
              final isSelected =
                  _selectedDate != null &&
                  _selectedDate!.year == date.year &&
                  _selectedDate!.month == date.month &&
                  _selectedDate!.day == date.day;
              final isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = date);
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : hasInterview
                        ? theme.colorScheme.primary.withAlpha(30)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: theme.colorScheme.primary, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isToday ? FontWeight.bold : null,
                        ),
                      ),
                      if (hasInterview && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInterviewCard(JobApplication job, ThemeData theme) {
    final interviewDate = DateTime.tryParse(job.interviewDate ?? '');
    final timeStr = interviewDate != null
        ? DateFormat('h:mm a').format(interviewDate)
        : 'Time not set';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withAlpha(30),
          child: Icon(Icons.event, color: theme.colorScheme.primary),
        ),
        title: Text(
          job.jobName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.companyName != null) Text(job.companyName!),
            Text(
              '🕐 $timeStr',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        ),
      ),
    );
  }

  // ============================================
  // FOLLOW-UPS TAB
  // ============================================
  Widget _buildFollowUpsTab(List<JobApplication> jobs, ThemeData theme) {
    // Filter jobs with follow-up dates
    final followUpJobs = jobs
        .where((j) => j.followUpDate != null && j.followUpDate!.isNotEmpty)
        .toList();

    // Sort by date
    followUpJobs.sort((a, b) {
      final dateA = DateTime.tryParse(a.followUpDate!) ?? DateTime(9999);
      final dateB = DateTime.tryParse(b.followUpDate!) ?? DateTime(9999);
      return dateA.compareTo(dateB);
    });

    // Group by urgency
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek = today.add(const Duration(days: 7));

    final overdue = <JobApplication>[];
    final todayList = <JobApplication>[];
    final thisWeek = <JobApplication>[];
    final later = <JobApplication>[];

    for (final job in followUpJobs) {
      final date = DateTime.tryParse(job.followUpDate!);
      if (date == null) continue;
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (dateOnly.isBefore(today)) {
        overdue.add(job);
      } else if (dateOnly.isAtSameMomentAs(today)) {
        todayList.add(job);
      } else if (dateOnly.isBefore(endOfWeek)) {
        thisWeek.add(job);
      } else {
        later.add(job);
      }
    }

    if (followUpJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text('No pending follow-ups!', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'All caught up 🎉',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (overdue.isNotEmpty) ...[
          _buildUrgencyHeader('🔴 Overdue', Colors.red, overdue.length),
          ...overdue.map((j) => _buildFollowUpCard(j, theme, isOverdue: true)),
        ],
        if (todayList.isNotEmpty) ...[
          _buildUrgencyHeader('🟠 Today', Colors.orange, todayList.length),
          ...todayList.map((j) => _buildFollowUpCard(j, theme)),
        ],
        if (thisWeek.isNotEmpty) ...[
          _buildUrgencyHeader('🟡 This Week', Colors.amber, thisWeek.length),
          ...thisWeek.map((j) => _buildFollowUpCard(j, theme)),
        ],
        if (later.isNotEmpty) ...[
          _buildUrgencyHeader('🟢 Later', Colors.green, later.length),
          ...later.map((j) => _buildFollowUpCard(j, theme)),
        ],
      ],
    );
  }

  Widget _buildUrgencyHeader(String title, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowUpCard(
    JobApplication job,
    ThemeData theme, {
    bool isOverdue = false,
  }) {
    final followUpDate = DateTime.tryParse(job.followUpDate ?? '');
    final dateStr = followUpDate != null
        ? DateFormat('MMM d, yyyy').format(followUpDate)
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isOverdue ? Colors.red.withAlpha(20) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue
              ? Colors.red.withAlpha(50)
              : theme.colorScheme.primary.withAlpha(30),
          child: Icon(
            isOverdue ? Icons.warning : Icons.notifications,
            color: isOverdue ? Colors.red : theme.colorScheme.primary,
          ),
        ),
        title: Text(
          job.jobName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (job.companyName != null) Text(job.companyName!),
            Text(
              '📅 $dateStr',
              style: TextStyle(color: isOverdue ? Colors.red : theme.hintColor),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
        ),
      ),
    );
  }
}
