using System;
using System.Drawing;
using System.Windows.Forms;
using WallpaperChanger.Models;
using WallpaperChanger.Services;

namespace WallpaperChanger.Controls;

/// <summary>
/// Control for configuring scheduled wallpaper rotations.
/// </summary>
public class ScheduleControl : UserControl
{
    private readonly ISchedulerService _schedulerService;
    private readonly IConfigurationService _configService;
    private readonly CheckBox _chkEnable;
    private readonly ComboBox _cmbInterval;
    private readonly Label _lblNextRotation;
    private readonly RadioButton _rbHistory;
    private readonly RadioButton _rbApi;
    private readonly Button _btnApply;
    private readonly Button _btnRotateNow;
    
    // Intervals in minutes and their display labels
    private readonly (string Label, int Minutes)[] _intervals = 
    {
        ("1 Minute", 1),
        ("15 Minutes", 15),
        ("30 Minutes", 30),
        ("1 Hour", 60),
        ("2 Hours", 120),
        ("4 Hours", 240),
        ("8 Hours", 480),
        ("24 Hours", 1440)
    };

    /// <summary>
    /// Initializes a new instance of the <see cref="ScheduleControl"/> class.
    /// </summary>
    public ScheduleControl(ISchedulerService schedulerService, IConfigurationService configService)
    {
        _schedulerService = schedulerService;
        _configService = configService;

        // Initialize UI
        this.Padding = new Padding(20);
        this.BackColor = Color.White;

        var mainLayout = new TableLayoutPanel
        {
            Dock = DockStyle.Fill,
            ColumnCount = 1,
            RowCount = 6,
            AutoSize = true
        };

        // Title
        var lblTitle = new Label 
        { 
            Text = "Scheduled Rotations", 
            Font = new Font("Segoe UI", 14, FontStyle.Bold),
            AutoSize = true,
            Margin = new Padding(0, 0, 0, 20)
        };

        // Enable Switch
        _chkEnable = new CheckBox
        {
            Text = "Enable Auto-Rotation",
            Font = new Font("Segoe UI", 10),
            AutoSize = true,
            Checked = _configService.Settings.IsSchedulerEnabled
        };

        // Interval Selection
        var pnlInterval = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight, Margin = new Padding(0, 10, 0, 10) };
        var lblInterval = new Label { Text = "Rotate Every:", Font = new Font("Segoe UI", 10), AutoSize = true, Anchor = AnchorStyles.Left };
        _cmbInterval = new ComboBox { DropDownStyle = ComboBoxStyle.DropDownList,  Font = new Font("Segoe UI", 10), Width = 150 };
        
        foreach (var (label, mins) in _intervals)
        {
            _cmbInterval.Items.Add(label);
        }
        
        // Select current interval
        int currentMins = _configService.Settings.SchedulerIntervalMinutes;
        int index = Array.FindIndex(_intervals, x => x.Minutes == currentMins);
        _cmbInterval.SelectedIndex = index >= 0 ? index : 2; // Default 1 Hour

        pnlInterval.Controls.Add(lblInterval);
        pnlInterval.Controls.Add(_cmbInterval);

        // Source Selection
        var grpSource = new GroupBox 
        { 
            Text = "Wallpaper Source", 
            Font = new Font("Segoe UI", 10), 
            AutoSize = true, 
            Dock = DockStyle.Top,
            Margin = new Padding(0, 10, 0, 10)
        };
        var pnlSource = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.TopDown, Dock = DockStyle.Fill, Padding = new Padding(10) };
        
        _rbHistory = new RadioButton { Text = "Random from History (Offline)", AutoSize = true, Checked = _configService.Settings.RotationSource == RotationSource.History };
        _rbApi = new RadioButton { Text = "Random from API (Requires Internet)", AutoSize = true, Checked = _configService.Settings.RotationSource == RotationSource.Api };
        
        pnlSource.Controls.Add(_rbHistory);
        pnlSource.Controls.Add(_rbApi);
        grpSource.Controls.Add(pnlSource);

        // Next Rotation Info
        _lblNextRotation = new Label 
        { 
            Text = "Next Rotation: Not Scheduled", 
            Font = new Font("Segoe UI", 10, FontStyle.Italic),
            AutoSize = true,
            ForeColor = Color.Gray,
            Margin = new Padding(0, 10, 0, 10)
        };

        // Buttons
        var pnlButtons = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.LeftToRight, Dock = DockStyle.Top };
        _btnApply = new Button { Text = "Apply Settings", AutoSize = true, BackColor = Color.FromArgb(0, 120, 215), ForeColor = Color.White, FlatStyle = FlatStyle.Flat, Padding = new Padding(10, 5, 10, 5) };
        _btnRotateNow = new Button { Text = "Rotate Now", AutoSize = true, BackColor = Color.LightGray, FlatStyle = FlatStyle.Flat, Padding = new Padding(10, 5, 10, 5), Margin = new Padding(10, 0, 0, 0) };

        pnlButtons.Controls.Add(_btnApply);
        pnlButtons.Controls.Add(_btnRotateNow);

        // Add to Layout
        mainLayout.Controls.Add(lblTitle);
        mainLayout.Controls.Add(_chkEnable);
        mainLayout.Controls.Add(pnlInterval);
        mainLayout.Controls.Add(grpSource);
        mainLayout.Controls.Add(_lblNextRotation);
        mainLayout.Controls.Add(pnlButtons);

        this.Controls.Add(mainLayout);

        // Wire Events
        _btnApply.Click += (s, e) => SaveAndApply();
        _btnRotateNow.Click += (s, e) => TriggerManualRotation();
        _schedulerService.NextRotationChanged += (s, time) => UpdateNextRotationLabel(time);

        // Initial Display
        UpdateUiState();
        _chkEnable.CheckedChanged += (s, e) => UpdateUiState();
    }

    private void UpdateUiState()
    {
        _cmbInterval.Enabled = _chkEnable.Checked;
        _rbHistory.Enabled = _chkEnable.Checked;
        _rbApi.Enabled = _chkEnable.Checked;
    }

    private async void SaveAndApply()
    {
        bool enabled = _chkEnable.Checked;
        int intervalMins = _intervals[_cmbInterval.SelectedIndex].Minutes;
        var source = _rbApi.Checked ? RotationSource.Api : RotationSource.History;

        await _schedulerService.UpdateConfigurationAsync(enabled, intervalMins, source);
        
        MessageBox.Show("Settings applied successfully.", "Scheduler", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private async void TriggerManualRotation()
    {
        _btnRotateNow.Enabled = false;
        try 
        {
            await _schedulerService.ForceRotationAsync();
            MessageBox.Show("Rotation completed!", "Success", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Rotation failed: {ex.Message}", "Error", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
        finally
        {
            _btnRotateNow.Enabled = true;
        }
    }

    private void UpdateNextRotationLabel(DateTime? time)
    {
        if (this.InvokeRequired)
        {
            this.Invoke(new Action(() => UpdateNextRotationLabel(time)));
            return;
        }

        if (time.HasValue)
        {
            var timeLeft = time.Value - DateTime.Now;
            _lblNextRotation.Text = $"Next Rotation: {time.Value:HH:mm:ss} (in {timeLeft.TotalMinutes:F1} mins)";
        }
        else
        {
            _lblNextRotation.Text = "Next Rotation: Disabled";
        }
    }
}
