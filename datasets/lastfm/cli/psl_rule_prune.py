import sys
import re
import numpy as np

# hardcoded rule groups for psl files for this dataset
rule_group_indices = [[[0], [1], [2]],
                      [[3], [4]],
                      [[5], [6]],
                      [[7], [8]],
                      [[9, 10], [11, 12], [13, 14]],
                      [[15, 16], [17, 18]]]


def main(argv):
    input_psl_file_path = argv[0]
    pruning_method = argv[1]
    output_psl_file_path = argv[2]

    # open file
    with open(input_psl_file_path, 'r') as original_psl_file:
        with open(output_psl_file_path, 'w') as pruned_psl_file:

            dropped_rule_indices = []

            original_lines = original_psl_file.readlines()
            original_psl_file.seek(0)

            # find all rules to prune using specified pruning method
            for rule_group in rule_group_indices:
                sub_group_maximums = []
                for sub_group in rule_group:
                    # get maximum value in subgroup
                    max_value = 0
                    for line_number in sub_group:
                        line = original_lines[line_number]
                        value = float(re.findall("\d+\.\d+", line)[0])
                        if value > max_value:
                            max_value = value

                    sub_group_maximums.append(max_value)

                # use heuristic/prune method to find dropped rule indices
                if pruning_method == 'TakeTopPruning':
                    top_sub_group_index = np.argmax(sub_group_maximums)
                    for sub_group_index, sub_group in enumerate(rule_group):
                        if sub_group_index != top_sub_group_index:
                            dropped_rule_indices = dropped_rule_indices + [index for index in sub_group]
                elif pruning_method == 'DropBottomPruning':
                    bottom_sub_group_index = np.argmin(sub_group_maximums)
                    for sub_group_index, sub_group in enumerate(rule_group):
                        if sub_group_index == bottom_sub_group_index:
                            dropped_rule_indices = dropped_rule_indices + [index for index in sub_group]

            # copy rules that are not in dropped_rule_indices list
            for line_index, line in enumerate(original_lines):
                if line_index not in dropped_rule_indices:
                    pruned_psl_file.write(line)


if __name__ == "__main__":
   main(sys.argv[1:])
