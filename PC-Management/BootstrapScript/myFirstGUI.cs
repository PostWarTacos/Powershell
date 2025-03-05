using System;
using System.Windows.Forms;

namespace DeviceSetupApp
{
    public class MainForm : Form
    {
        // Device buttons
        private Button btnDesktop;
        private Button btnWorkLaptop;
        private Button btnSurfacePro;

        // Group box for actions
        private GroupBox groupActions;

        // Example checkbox for an application action
        private CheckBox chkInstallApp1;

        // Slider for a setting (e.g., mouse pointer size)
        private TrackBar trackMouseSize;

        // Run button to execute actions
        private Button btnRun;

        public MainForm()
        {
            InitializeComponents();
        }

        private void InitializeComponents()
        {
            // Form settings
            this.Text = "Device Setup";
            this.Size = new System.Drawing.Size(800, 600);
            this.StartPosition = FormStartPosition.CenterScreen;

            // Initialize device buttons
            btnDesktop = new Button();
            btnDesktop.Text = "Matt's Desktop";
            btnDesktop.Location = new System.Drawing.Point(10, 10);
            btnDesktop.Size = new System.Drawing.Size(150, 30);
            btnDesktop.Click += BtnDesktop_Click;

            btnWorkLaptop = new Button();
            btnWorkLaptop.Text = "Matt's Work Laptop";
            btnWorkLaptop.Location = new System.Drawing.Point(170, 10);
            btnWorkLaptop.Size = new System.Drawing.Size(150, 30);
            btnWorkLaptop.Click += BtnWorkLaptop_Click;

            btnSurfacePro = new Button();
            btnSurfacePro.Text = "Matt's Surface Pro";
            btnSurfacePro.Location = new System.Drawing.Point(330, 10);
            btnSurfacePro.Size = new System.Drawing.Size(150, 30);
            btnSurfacePro.Click += BtnSurfacePro_Click;

            // Initialize group box for actions
            groupActions = new GroupBox();
            groupActions.Text = "Actions";
            groupActions.Location = new System.Drawing.Point(10, 50);
            groupActions.Size = new System.Drawing.Size(760, 400);

            // Example: Initialize checkbox for installing an app
            chkInstallApp1 = new CheckBox();
            chkInstallApp1.Text = "Install App1";
            chkInstallApp1.Location = new System.Drawing.Point(20, 30);
            chkInstallApp1.AutoSize = true;
            groupActions.Controls.Add(chkInstallApp1);

            // Example: Initialize a trackbar for adjusting mouse pointer size
            trackMouseSize = new TrackBar();
            trackMouseSize.Minimum = 10;
            trackMouseSize.Maximum = 30;
            trackMouseSize.Value = 10;
            trackMouseSize.TickFrequency = 2;
            trackMouseSize.Location = new System.Drawing.Point(20, 70);
            trackMouseSize.Size = new System.Drawing.Size(200, 45);
            groupActions.Controls.Add(trackMouseSize);

            // Initialize the Run button
            btnRun = new Button();
            btnRun.Text = "Run";
            btnRun.Location = new System.Drawing.Point(10, 500);
            btnRun.Size = new System.Drawing.Size(100, 30);
            btnRun.Click += BtnRun_Click;

            // Add controls to the main form
            this.Controls.Add(btnDesktop);
            this.Controls.Add(btnWorkLaptop);
            this.Controls.Add(btnSurfacePro);
            this.Controls.Add(groupActions);
            this.Controls.Add(btnRun);
        }

        // Device button click handlers set default configurations
        private void BtnDesktop_Click(object sender, EventArgs e)
        {
            // Set predetermined options for Matt's Desktop
            chkInstallApp1.Checked = true;
            MessageBox.Show("Desktop profile selected. Default actions applied.");
        }

        private void BtnWorkLaptop_Click(object sender, EventArgs e)
        {
            // Set predetermined options for Matt's Work Laptop
            chkInstallApp1.Checked = false;
            MessageBox.Show("Work Laptop profile selected. Default actions applied.");
        }

        private void BtnSurfacePro_Click(object sender, EventArgs e)
        {
            // Set predetermined options for Matt's Surface Pro
            chkInstallApp1.Checked = true;
            MessageBox.Show("Surface Pro profile selected. Default actions applied.");
        }

        // Run button click handler executes selected actions
        private void BtnRun_Click(object sender, EventArgs e)
        {
            // Check which actions are selected
            if (chkInstallApp1.Checked)
            {
                // Execute the corresponding action
                MessageBox.Show("Executing: Install App1");
                // You would call your installation method here
            }

            // Retrieve the value from the slider
            int pointerSize = trackMouseSize.Value;
            MessageBox.Show($"Setting mouse pointer size to {pointerSize}");

            // Additional actions can be added here following a similar pattern
        }

        [STAThread]
        public static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}
