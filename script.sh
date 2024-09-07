#!/bin/bash
source /usr/local/gromacs/bin/GMXRC
grep -v HOH structure.pdb > structure_clean.pdb
echo "15 0" | gmx pdb2gmx -f structure_clean.pdb -o structure_processed.gro -water spce
gmx editconf -f structure_processed.gro -o structure_newbox.gro -c -d 1.0 -bt cubic
gmx solvate -cp structure_newbox.gro -cs spc216.gro -o structure_solv.gro -p topol.top
gmx grompp -f ions.mdp -c structure_solv.gro -p topol.top -o ions.tpr -maxwarn 3
echo "SOL" | gmx genion -s ions.tpr -o structure_solv_ions.gro -p topol.top -pname NA -nname CL -neutral
gmx grompp -f minim.mdp -c structure_solv_ions.gro -p topol.top -o em.tpr
gmx mdrun -v -deffnm em
echo "Potential" | gmx energy -f em.edr -o potential.xvg
gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol.top -o nvt.tpr
gmx mdrun -v -deffnm nvt
echo "Temperature" | gmx energy -f nvt.edr -o temperature.xvg
gmx grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o npt.tpr
gmx mdrun -v -deffnm npt
echo "Pressure" | gmx energy -f npt.edr -o pressure.xvg
echo "Density" | gmx energy -f npt.edr -o density.xvg
gmx grompp -f md.mdp -c npt.gro -t npt.cpt -p topol.top -o md_0_1.tpr
gmx mdrun -v -deffnm md_0_1
echo "Protein System" | gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_0_1_noPBC.xtc -pbc mol -center
echo "Backbone Backbone" | gmx rms -s md_0_1.tpr -f md_0_1_noPBC.xtc -o rmsd.xvg -tu ns
echo "Backbone Backbone" |  gmx rms -s em.tpr -f md_0_1_noPBC.xtc -o rmsd_xtal.xvg -tu ns
echo "Protein" | gmx gyrate -s md_0_1.tpr -f md_0_1_noPBC.xtc -o gyrate.xvg
